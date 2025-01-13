module "bootstrap" {
  source                = "./bootstrap"
  user                  = var.user
  pg_user_vault         = var.pg_user_vault
  pg_password_vault     = var.pg_password_vault
  pg_user_terraform     = var.pg_user_terraform
  pg_password_terraform = var.pg_password_terraform
}
