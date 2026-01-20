# Bucket na kod funkcji
resource "google_storage_bucket" "functions" {
  name          = "${var.project_id}-functions-src"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "functions_zip" {
  name   = "functions.zip"
  bucket = google_storage_bucket.functions.name
  source = "../functions/functions.zip"
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
        object = google_storage_bucket_object.functions_zip.name
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
        object = google_storage_bucket_object.functions_zip.name
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
resource "google_cloudfunctions2_function" "check_prices" {
  name     = "check-prices"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = "check_prices"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = google_storage_bucket_object.functions_zip.name
      }
    }
  }

  service_config {
    available_memory = "512M"
    timeout_seconds  = 540
    ingress_settings = "ALLOW_ALL"
    environment_variables = {
      PROJECT_ID = var.project_id
    }
  }
}


# Scheduler check_prices
resource "google_cloud_scheduler_job" "check_prices" {
  name      = "check-prices-job"
  region    = var.region
  schedule  = "*/10 * * * *"
  time_zone = "Europe/Warsaw"

  http_target {
    uri         = google_cloudfunctions2_function.check_prices.service_config[0].uri
    http_method = "GET"
  }
}

# delete_product
resource "google_cloudfunctions2_function" "delete_product" {
  name     = "delete-product"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "delete_product"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = google_storage_bucket_object.functions_zip.name
      }
    }
  }

  service_config {
    available_memory = "256M"
    timeout_seconds  = 30
    ingress_settings = "ALLOW_ALL"
  }
}

# send_email
resource "google_cloudfunctions2_function" "send_email" {
  name     = "send-email"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = "send_email"

    source {
      storage_source {
        bucket = google_storage_bucket.functions.name
        object = google_storage_bucket_object.functions_zip.name
      }
    }
  }

  event_trigger {
    event_type  = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.send_email.id
    trigger_region = var.region
  }

  service_config {
    available_memory = "512M"
    timeout_seconds  = 540
    environment_variables = {
      GMAIL_USER         = var.gmail_user
      GMAIL_APP_PASSWORD = var.gmail_app_password
      PROJECT_ID         = var.project_id
    }
  }
}


resource "google_pubsub_topic" "send_email" {
  name = "send-email"
}

resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = toset([
    google_cloudfunctions2_function.add_product.name,
    google_cloudfunctions2_function.get_products.name,
    google_cloudfunctions2_function.delete_product.name,
    google_cloudfunctions2_function.check_prices.name
  ])
  
  service  = each.value
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}