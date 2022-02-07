provider "google" {
  version = "~> 2.20"
  project = var.project_id
}

data "google_project" "project" {}
resource "google_cloud_scheduler_job" "scheduler" {
  name = "scheduler-data"
  schedule = "0 0 * * *"
  region = var.region

  http_target {
    http_method = "POST"
    uri = "https://dataflow.googleapis.com/v1b3/projects/${var.project_id}/locations/${var.region}/templates:launch?gcsPath=gs://${var.bucket}/templates/dataflow-data-template"
    oauth_token {
      service_account_email = google_service_account.cloud-scheduler-data.email
    }

    # need to encode the string
    body = base64encode(<<-EOT
    {
      "jobName": "test-cloud-scheduler",
      "parameters": {
        "region": "${var.region}"
      },
      "environment": {
        "maxWorkers": "10",
        "tempLocation": "gs://${var.bucket}/temp",
        "zone": "${var.region}-a",
        "serviceAccountEmail": "${google_service_account.cloud-scheduler-data.email}"
      }
    }
EOT
    )
  }
}

resource "google_service_account" "cloud-scheduler-data" {
  account_id = "scheduler-dataflow-data"
  display_name = "A service account for running dataflow from cloud scheduler"
}

resource "google_project_iam_member" "cloud-scheduler-dataflow-admin" {
  project = var.project_id
  role = "roles/dataflow.admin"
  member = "serviceAccount:${google_service_account.cloud-scheduler-data.email}"
}

resource "google_project_iam_member" "cloud-scheduler-dataflow-worker" {
  project = var.project_id
  role = "roles/dataflow.worker"
  member = "serviceAccount:${google_service_account.cloud-scheduler-data.email}"
}

resource "google_project_iam_member" "cloud-scheduler-storage-admin" {
  project = var.project_id
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloud-scheduler-data.email}"
}
