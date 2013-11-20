class ReceiverController < ApplicationController
	def index
		client = Databasedotcom::Client.new

		client.authenticate(username: ENV['SF_USERNAME'], password: ENV['SF_PASSWORD'])

		doc = Nokogiri::XML(request.body.read)

		client.materialize("Contact")

		render text: Contact.all.to_yaml
	end

	def receive
		request_body = request.body.read
		Rails.logger.debug request_body

		doc = Nokogiri::XML(request_body)

		status = doc.css('EnvelopeStatus > Status')[0].inner_text
		if status != 'Completed'
			Rails.logger.debug "Status: #{status}, skipping..."
			return render text: 'OK'
		end

		client = Databasedotcom::Client.new
		client.authenticate(username: ENV['SF_USERNAME'], password: ENV['SF_PASSWORD'])
		client.debugging = true

		client.materialize("Contact")


		recipient_status = doc.css('RecipientStatus')[0]
		document_status = doc.css('DocumentStatus')[0]

		contact = Contact.new

		name = recipient_status.css('UserName').text
		name_parts = name.split(' ', 2)
		contact.FirstName = name_parts[0]
		contact.LastName = name_parts.fetch(1, '[not provided]')
		contact.Email = recipient_status.css('Email').text
		contact.Description = "Received document #{document_status.css('Name').text} - recipient ID #{recipient_status.css('RecipientId').text}"
		contact.OwnerId = client.user_id
		Rails.logger.debug contact.save

		render text: params.to_yaml
	end
end