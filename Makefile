.PHONY: state

state:
	TYPE=$(terraform state list | fzf); \
	terraform state show $$TYPE
