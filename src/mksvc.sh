#!/bin/bash
color_text() {
	gum style --bold  --foreground '#ca9ee6' "$1"
}
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 'Terraform/Proxmox CLI'

dry_run=$(gum confirm "Dry run?" && echo "1" || echo "0")
echo "$(color_text 'Dry run?') $([ $dry_run -eq 1 ] && echo 'yes' || echo 'no')"

name=$(gum input --placeholder "service name")
echo "$(color_text 'Service name:') $name"

systemd=$(gum confirm "Create a .service file?" && echo "1" || echo "0")
echo "$(color_text 'Systemd?') $([ $systemd -eq 1 ] && echo 'yes' || echo 'no')"

templates=$(ls ./templates)
type=$(gum choose --header "Select type of resource" $templates)
echo "$(color_text 'Service type:') $type"

if [ "$dry_run" -eq 1 ]; then
	echo "Dry run fs"
	echo "create ./$name/"
	echo "create ./$name/provision.sh"
	echo "create./$name/startup.sh"
	echo ""
	echo "TF Templ"
	[ "$systemd" -eq 1 ] && echo "./$name/$name.service"
	cat "./templates/$type" | sed -E "s/TEMPLATE/$name/g"
else
	mkdir "$name"
	touch "$name/provision.sh"
	touch "$name/startup.sh"
	touch "deploy/$name.tf"
	[ "$systemd" -eq 1 ] && touch "$name/$name.service"
	cat "./templates/$type" | sed -E "s/TEMPLATE/$name/g" > "deploy/$name.tf"
fi
