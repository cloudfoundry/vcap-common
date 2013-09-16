require 'oauthclient'

# Get your own consumer token from http://twitter.com/apps
consumer_key = '3MVG9y6x0357HledNGHa9tJrrlOmpCSo5alTv4W4AG1M0f9a8cGBIwo5wN2bQ7hjAEsjD7SBWf3H2Oycc9Qql'
consumer_secret = '1404017425765973464'

callback = ARGV.shift # can be nil for OAuth 1.0. (not 1.0a)
request_token_url = 'https://login.salesforce.com/_nc_external/system/security/oauth/RequestTokenHandler'
oob_authorize_url = 'https://login.salesforce.com/setup/secur/RemoteAccessAuthorizationPage.apexp'
access_token_url = 'https://login.salesforce.com/_nc_external/system/security/oauth/AccessTokenHandler'

STDOUT.sync = true

# create OAuth client.
client = OAuthClient.new
client.oauth_config.consumer_key = consumer_key
client.oauth_config.consumer_secret = consumer_secret
client.oauth_config.signature_method = 'HMAC-SHA1'
client.oauth_config.http_method = :get # Twitter does not allow :post
client.debug_dev = STDERR if $DEBUG

client.ssl_config.ssl_version = "TLSv1_1"

# Get request token.
res = client.get_request_token(request_token_url, callback)
p res.status
p res.oauth_params
p res.content
p client.oauth_config
token = res.oauth_params['oauth_token']
secret = res.oauth_params['oauth_token_secret']
raise if token.nil? or secret.nil?

# You need to confirm authorization out of band.
puts
puts "Go here and do confirm: #{oob_authorize_url}?oauth_token=#{token}&oauth_consumer_key=#{consumer_key}"
puts "Type oauth_verifier/PIN (if given) and hit [enter] to go"
verifier = gets.chomp
verifier = nil if verifier.empty?

# Get access token.
# FYI: You may need to re-construct OAuthClient instance here.
#      In normal web app flow, getting access token and getting request token
#      must be done in different HTTP requests.
#  client = OAuthClient.new
#  client.oauth_config.consumer_key = consumer_key
#  client.oauth_config.consumer_secret = consumer_secret
#  client.oauth_config.signature_method = 'HMAC-SHA1'
#  client.oauth_config.http_method = :get # Twitter does not allow :post
res = client.get_access_token(access_token_url, token, secret, verifier)
p res.status
p res.oauth_params
p res.content
p client.oauth_config
id = res.oauth_params['user_id']

puts
puts "Access token usage example"
puts "Hit [enter] to go"
gets

# Access to a protected resource. (DM)
puts client.get("http://twitter.com/direct_messages.json")
