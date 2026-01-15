resource "google_storage_bucket" "frontend" {
  name     = "${var.project_id}-frontend"
  location = "EU"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "frontend_public" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "frontend_files" {
  for_each = fileset("../frontend/build", "**")

  name   = each.value
  bucket = google_storage_bucket.frontend.name
  source = "../frontend/build/${each.value}"
}
