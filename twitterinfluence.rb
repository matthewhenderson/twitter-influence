# Matthew Henderson
# 2012-03-19

require 'rubygems'
require 'twitter'

## UNCOMMENT AND PUT YOUR OAUTH INFORMATION IN BELOW
#Twitter.configure do |config|
  #config.consumer_key = 'xxxxxxxxxxxxxxxxxxxxxx'
  #config.consumer_secret = 'xxxxxxxxxxxxxxxxxxxxxx'
  #config.oauth_token = 'xxxxxxxxxxxxxxxxxxxxxx'
  #config.oauth_token_secret = 'xxxxxxxxxxxxxxxxxxxxxx'
#end

#####################################
## PROCESS THE DATA           
#####################################

@twitterclient = Twitter::Client.new   
@writefile = "twitterconnections" + Time.now().to_i.to_s + ".dot"

def gettwitterinfluence
  writefileheader  
  gettheirfollowers
  getfollowersofthefollowers
  writefilefooter
end

def checkratelimit   
  ratelimit = @twitterclient.rate_limit_status.remaining_hits.to_i
  puts "RATE LIMIT IS: " + ratelimit.to_s  
  if ratelimit < 20 
    @ratelimited = true  
    while @ratelimited == true do
      puts "CURRENTLY RATE LIMITED..... waiting 15 minutes......"    
      sleep(900)      
      ratelimit = @twitterclient.rate_limit_status.remaining_hits.to_i
      puts "RATE LIMIT IS: " + ratelimit.to_s
      if ratelimit > 50 
        @ratelimited = false
      end
    end  
  else 
    @ratelimited = false
  end
end

def gettheirfollowers
  getuserinfo(@username)
  getfollowerinfo(@userid)
  @theirfollowers = @followers
  recordfollowers(@userid,@followers)
end

def getfollowersofthefollowers
  @theirfollowers.each do |follower|
    accountinfo = Twitter.user(follower)
    #get their followers if not a private account
    if accountinfo.protected != true          
      getfollowerinfo(follower)  
      recordfollowers(follower,@followers)
    end
  end
end

def getuserinfo(twitterer)
  @user = Twitter.user(twitterer)
  @userid = @user.id
end

def getfollowerinfo(userid)
  cursor = "-1"
  @followers = []
  while cursor != 0 do
   followerids = Twitter.follower_ids(userid,{:cursor=>cursor})
   @followers += followerids.ids
   cursor = followerids.next_cursor
   checkratelimit    
  end
end

def recordfollowers(userid,followers)
  followers.each do |follower|
    line = follower.to_s + " -> " + userid.to_s + "\n"
    File.open(@writefile, 'a') {|f| f.write(line) }   
    puts line
  end
end

def writefileheader
  line = "digraph mentions {\n"
  File.open(@writefile, 'a') {|f| f.write(line) }
end

def writefilefooter
  line = "}"
  File.open(@writefile, 'a') {|f| f.write(line) }
end

########################################
## NOW KICK IT ALL OFF               
######################################

## get the Twitter userame to be examined
puts "Which Twitter user do you want to research?"
print '> '
@username = STDIN.gets.chomp()
gettwitterinfluence

########################################
## ONCE THAT IS FINISHED, GIVE
## INSTRUCTIONS TO CREATE THE GRAPH.
#######################################

puts "************************************"
puts "Run the following command."
puts "Requires graphviz."
puts "http://www.graphviz.org/ \n\n"
puts "more #{@writefile} | sfdp -Gbgcolor=white -Ncolor='#660000' -Ecolor='#660000' -Nwidth=0.1 -Nheight=0.1 -Nfixedsize=true -Nlabel='' -Earrowsize=0.7 -Gsize=50 -Gratio=fill -Tpng > twitterinfluence-#{@username}.png"


