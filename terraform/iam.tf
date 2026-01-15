resource "google_project_iam_member" "firestore_access" {
  project = var.project_id
  role   = "roles/datastore.user"
  member = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}
