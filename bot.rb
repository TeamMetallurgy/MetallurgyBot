require 'cinch'


$admin_room = '#TeamMetallurgy'
$room = '#Metallurgy'

$bot_name = 'MetallurgyBot'
$server = 'localhost'

$requests = {}


class Request < Struct.new(:nick,:name, :channel)

end


bot = Cinch::Bot.new do
  configure do |c|
    c.nick      = $bot_name
    c.realname  = $bot_name
    c.server    = $server
    c.channels  = [$room, $admin_room]
  end


  on :message, /^!request (.+)/ do |m, minecraftname|

    $requests[minecraftname] = Request.new(m.user.nick, minecraftname, m.channel)

    Channel($admin_room).send "#{m.user.nick} has request to be white-listed with the name #{minecraftname}."
    Channel($admin_room).send  "To accept type: !accept #{minecraftname}"
    Channel($admin_room).send  "To deny type: !deny #{minecraftname}"
  end

  on :message, /^!accept (.+)/ do |m, minecraftname|
    if $requests.has_key?(minecraftname)
      current_request = $requests.delete(minecraftname)
      Channel(current_request.channel).send "#{current_request.nick} has been added to the white-list by #{m.user.nick}."
    else
      m.reply "Request not found for name \"#{minecraftname}\"."
    end
  end

  on :message, /^!deny (.+)/ do |m, minecraftname|
    if $requests.has_key?(minecraftname)
      current_request = $requests.delete(minecraftname)
      Channel(current_request.channel).send "#{current_request.nick} has been denied to be white-listed by #{m.user.nick}."
    else
      m.reply "Request not found for name \"#{minecraftname}\"."
    end
  end

  on :message, /^!request-list/ do |m|
    if $requests.empty?
      m.reply 'No pending white-list applications.'
    else
      m.reply "#{$requests.size} Pending white-list applications:"
      $requests.each_with_index { |(name, request), index| m.reply "#{index}: #{request.name}" }
    end
  end
end

bot.start
