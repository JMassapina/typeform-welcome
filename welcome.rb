require 'sinatra'
require 'json'
require 'slack-ruby-client'
require 'yaml'
require 'rest-client'

set :port, 4567

$welcome_typeform_ids = {
  form_id: 'rElE8H',
  first_name_id: 'qgXp',
  last_name_id: 'URU1',
  email_id: '48527284',
  company_id: 'cbuh',
  legal_id: '48527512',
  person_id: 'wbMx'
}

$slack_api_token = ENV["SLACK_API_TOKEN"]

$people = YAML.load_file('typeformers.yml')

get '/health' do
  [200, 'OK']
end

post '/signin' do
  response = JSON.parse(request.body.read)
  form_id = response['form_response']['form_id']

  halt 403 unless form_id == $welcome_typeform_ids.fetch(:form_id)

  answers = response['form_response']['answers']

  first_name_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:first_name_id) }
  first_name = first_name_object.first.fetch('text')

  last_name_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:last_name_id) }
  last_name = last_name_object.first.fetch('text')

  company_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:company_id) }
  company = company_object.first.fetch('text')

  person_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:person_id) }
  person = person_object.first.fetch('choice').fetch('label')

  person_slack = $people.key(person)

  $web_client = Slack::Web::Client.new(token: $slack_api_token)

  begin
    $web_client.chat_postMessage(
      channel: '@' + person_slack,
      text: 'Boo! ' + person + '! ' + first_name + ' ' + last_name + ' from ' + company + ' is here to scare you. Make your way to Barception, but be careful on your way!',
      username: 'Boo!',
      icon_emoji: ':jack_o_lantern:'
    )
  rescue Exception
    return [400, 'Bad Request']
  end

  [200, 'OK']

end
