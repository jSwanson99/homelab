resource "postgresql_role" "kubernetes_user" {
  name     = var.pg_user_kubernetes
  password = var.pg_password_kubernetes
  login    = true
}

resource "postgresql_database" "kubernetes_db" {
  name  = var.pg_database_kubernetes
  owner = postgresql_role.kubernetes_user.name
}

resource "postgresql_grant" "database_privileges" {
  database    = postgresql_database.kubernetes_db.name
  role        = postgresql_role.kubernetes_user.name
  object_type = "database"
  privileges  = ["ALL"]
}

resource "postgresql_grant" "schema_privileges" {
  database    = postgresql_database.kubernetes_db.name
  role        = postgresql_role.kubernetes_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["ALL"]
}
