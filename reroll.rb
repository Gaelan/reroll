require "open-uri"
require "json"
issue_number = ARGV[0]
issue = open "https://drupal.org/node/#{issue_number}/project-issue/json" do |json|
    JSON.load json
end
def cmd command, return_result = false
    puts command
    if return_result
        result = `#{command}`
    else
        system command
    end
    result
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
                        attachments.select { |attachment| comments[attachment["commentId"]]["commentNumber"] == number }[0]
                    else
                        attachments.last
                    end
if chosen_attachment["urls"].count != 1
    puts "This comment has more than one patch. Bug Gaelan to make this work."
    exit 1
end
# Get the date.
date = comments[chosen_attachment["commentId"]]["created"]
# Get the commit it worked on.
puts "If this breaks, make sure you are in a git clone of D8."
commit_hash = cmd "git log --before=#{date} -1 --pretty=format:%H", true
# Make a branch.
cmd "git checkout -b #{issue_number} #{commit_hash}"
# Apply the patch
cmd "curl #{chosen_attachment["urls"].values[0]}|git apply --index"
# Commit it
cmd "git add *"
cmd "git commit -m #{comments[chosen_attachment["commentId"]]["commentNumber"]}"
# Rebase!
cmd "git rebase 8.x"
puts "I will now start your shell. Resolve any conflicts, then exit."
system ENV["SHELL"]
cmd "git rebase --continue"
puts "We're done! Make a patch and put it up on d.o. Don't forget to set the status to needs review, and remove the Needs reroll tag!"
