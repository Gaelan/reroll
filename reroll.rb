require "open-uri"
require "json"
require "awesome_print"
issue_number = ARGV[0]
issue = open "https://drupal.org/node/#{issue_number}/project-issue/json" do |json|
    JSON.load json
end
attachments = issue["attachments"]
comments = issue["comments"]
# Add comment numbers to comments
comments.each do |id, comment|
    comment["commentNumber"] = comment["subject"][/#([0-9]+)/, 1].to_i
end
# Convert the attachments from a hash to a array.
attachments = attachments.values
# Drop non-patch attachments because we don't need them.
attachments.select! do |attachment|
    attachment["urls"].select! do |url|
        !(url =~ /\.patch$/)
    end
    attachment["urls"].size != 0
end
# Sort attachments by comment order
attachments.sort_by! do |attatchment|
    attatchment["commentNumber"]
end
# Decide on an attachment.
chosen_attachment = if ARGV[1]
                        number = ARGV[1].to_i
                        attachments.select { |attachment| comments[attachment["commentId"]]["commentNumber"] == number }.to_i
                    else
                        attachments.last
                    end
ap chosen_attachment
