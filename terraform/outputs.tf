# Gen1
output "check_prices_url" {
  value = google_cloudfunctions_function.check_prices.https_trigger_url
}


# Gen2
output "add_product_url" {
  value = google_cloudfunctions2_function.add_product.service_config[0].uri
}

output "get_products_url" {
  value = google_cloudfunctions2_function.get_products.service_config[0].uri
}
