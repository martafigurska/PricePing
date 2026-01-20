resource "google_project_iam_member" "firestore_access" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

resource "google_cloud_run_service_iam_member" "check_prices_invoker" {
  service  = google_cloudfunctions2_function.check_prices.name
  location = google_cloudfunctions2_function.check_prices.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_member" "scheduler_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}
