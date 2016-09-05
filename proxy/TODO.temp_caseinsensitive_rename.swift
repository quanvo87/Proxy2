/*
 
 when leave convo, have to notify convo view to pop as well
 
 *****
 
 when send message, always make sure to update the receiver's:
    - convo
    - proxy/convo
    - proxy
    - global unread
 
 (unless they have blocked you. more on this later)
 
 must account for the fact that he may have left the conversation. meaning his
 convo and proxy/convo will not exist. must re-create them.
 
 *****
 
 when leave a convo, you delete your copy of it, and your proxy/convo copy of it
 so it no longer shows up in your:
    - conversations feed
    - your proxy's feed in which it belonged.
 
 your unread count for that proxy and globally is also decremented by any
 remaning unread messages you had in that convo.
 
 that user will be able to message you again (until you block them). when they
 message you again, your convo and proxy/convo is re-created.
 
 all previous messages from the conversation will still be there.
 
 when both people leave a convo, both of their
 
 
 
 
 
 
 *****
 
 When a convo is created, it is given the key of its two proxy participants'
 names, alphabetized and concatenated. Since proxy names are unique, and a proxy
 cannot conversate with itself, this key will also be unique.
 
 Since messages are located in
    
    /messages/convo.name/
 
 messages persist through a conversation 'dying' (when both people leave the
 convo).
 
 *****
 
 When a message is 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 add freeze ui on proxy pull
 
 toggle photos/videos in chat
 data detection in chat
 unread receipts
 pull out time stamps?
 
 pull certain amount of data at a time, and pull more as needed
 
 profanity filter
 
 add that meta data to users
 maybe fire streaks, hearts
 
 fancy convo titles
 
 toggle sound
 
 recent list in new message
 
 add the images
 fanciest log in screen possible
 swipe/page libraries
 fancy custom nav bar library
 
 case 0:
 cell.textLabel?.text = "Messages Received"
 return cell
 case 1:
 cell.textLabel?.text = "Messages Sent"
 return cell
 case 2:
 cell.textLabel?.text = "Proxies Interacted With"
 return cell
 case 3:
 cell.textLabel?.text = "Date Created"
 return cell
 
 level up you proxy by getting some kind of currency. love, likes, pp (proxy points)
 you can only receive pp by
 every day each user's pp resets to 3
 leaderboard
 you can send however many you want to any proxy not yours
 level up for new icons, borders, colors, glowy effects, etc
 
 can never buy pp. just real money only items.
 
 can buy names in shop maybe.

            
 buy emojis
 buy business names
 
 
 buy new icon options for your proxies
 prestigious text color, look, animations for your name and messages
 several different tiers, shows in your proxy detail
 starting at $1 to up to ridiculous like thousands. let people show off
 can auction for names like pikachu or something
 sell/trade names?
 every week, lottery. 1% of proxies randomly chosen get a random level upgrade. could be any level!
 maybe as you use a proxy more, you level it up, and gain prestige there
 
 */