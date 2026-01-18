# Bucket na kod funkcji
resource "google_storage_bucket" "functions" {
  name     = "${var.project_id}-functions-src"
  location = var.region
}

# add_product
resource "google_cloudfunctions2_function" "add_product" {
  name     = "add-product"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = "add_product"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = "functions.zip"
      }
    }
  }

  service_config {
    available_memory = "512M"
    timeout_seconds  = 60
    ingress_settings = "ALLOW_ALL"
    
  }
}

# get_products
resource "google_cloudfunctions2_function" "get_products" {
  name     = "get-products"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = "get_products"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = "functions.zip"
      }
    }
  }

  service_config {
    available_memory = "512M"
    timeout_seconds  = 60
    ingress_settings = "ALLOW_ALL"
  }
}

# check_prices
resource "google_cloudfunctions_function" "check_prices" {
  name        = "check-prices"
  runtime     = "python310"
  entry_point = "check_prices"
  region      = var.region

  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = "functions.zip"
  trigger_http          = true

  available_memory_mb   = 512
  timeout               = 540
}


# Scheduler check_prices
resource "google_cloud_scheduler_job" "check_prices" {
  name      = "check-prices-job"
  region    = var.region
  schedule  = "0 * * * *"
  time_zone = "Europe/Warsaw"

  http_target {
    uri         = google_cloudfunctions_function.check_prices.https_trigger_url
    http_method = "GET"
  }
}

resource "google_cloudfunctions2_function" "delete_product" {
  name     = "delete-product"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "delete_product"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = "functions.zip"
      }
    }
  }

  service_config {
    available_memory = "256M"
    timeout_seconds  = 30
    ingress_settings = "ALLOW_ALL"
  }
}

resource "google_cloud_run_service_iam_member" "add_product_invoker" {
  service  = google_cloudfunctions2_function.add_product.name
  location = google_cloudfunctions2_function.add_product.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "get_products_invoker" {
  service  = google_cloudfunctions2_function.get_products.name
  location = google_cloudfunctions2_function.get_products.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "delete_product_invoker" {
  service  = google_cloudfunctions2_function.delete_product.name
  location = google_cloudfunctions2_function.delete_product.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}