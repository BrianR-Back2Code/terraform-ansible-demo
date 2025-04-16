variable "key_name" {
  description = "Name des SSH-Schlüsselpaars für EC2"
  type        = string
}

variable "private_key_path" {
  description = "Pfad zur privaten SSH-Schlüsseldatei"
  type        = string
}
