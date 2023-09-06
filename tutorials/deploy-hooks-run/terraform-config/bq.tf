resource "google_bigquery_dataset" "change_management" {
  dataset_id                  = "change_management"
  friendly_name               = "changes"
  description                 = "This is a change management dataset"
  location                    = "US"
  default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "changes" {
  dataset_id          = google_bigquery_dataset.change_management.dataset_id
  table_id            = "changes"
  deletion_protection = false

  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
  {
    "name": "service",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Service name"
  },
  {
    "name": "date",
    "type": "DATETIME",
    "defaultValueExpression": "CURRENT_DATETIME()",
    "description": "Change ate and time "
  },
  {
    "name": "change-status",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Change result, success or fail"
  }
]
EOF
}

resource "google_bigquery_table_iam_member" "member" {
  dataset_id = google_bigquery_dataset.change_management.dataset_id
  table_id   = google_bigquery_table.changes.table_id
  role       = "roles/bigquery.dataOwner"
  member     = "serviceAccount:${google_service_account.compute_service_account.email}"
}
