resource "google_firestore_database" "default" {
  name        = "(default)"
  location_id = "eur3"               
  type        = "FIRESTORE_NATIVE"  

  lifecycle {
    prevent_destroy = true           # nie pozwala Terraform usunąć bazy
    ignore_changes  = [name, location_id, type]  
  }
}
