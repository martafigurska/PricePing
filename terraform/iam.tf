resource "google_project_iam_member" "firestore_access" {
  project = var.project_id
  role   = "roles/datastore.user"
  member = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}
resource "google_cloudfunctions_function_iam_member" "check_prices_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.check_prices.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
