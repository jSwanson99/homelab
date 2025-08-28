user = User.find_by(username: 'root')
existing_token = user.personal_access_tokens.active.find_by(name: 'terraform-token')

if existing_token
 puts "Token 'terraform-token' already exists (ID: #{existing_token.id})"
else
 token = user.personal_access_tokens.create!(
   name: 'terraform-token',
   scopes: ['api'],
   expires_at: 1.year.from_now
 )
 puts "Created new token: #{token.token}"
end
