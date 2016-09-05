/*
 
 when leave convo, have to notify convo view to pop as well
 
 ***** The Proxy *****
 
 ***** Creating A Proxy *****
 
 Proxies are unique handles that users use to communicate with each other. A
 user can create as many proxies as they want, and communicate to any other
 proxy they want (as long as it's not their own). A proxy consists of a random
 adjective, capitalized noun, and then a number from 1-99. As of 9/5/16, there
 are around 250,000,000 possible proxies.
 
 To create a proxy, we first must make sure the word bank is loaded. I am
 currently hosting a JSON of the words at some JSON hosting site. If it's not
 loaded, we load it then call create proxy again. If it's already loaded, we
 proceed as usual.
 
 The next step after that is to go ahead and create and write a proxy. Our
 ProxyNameGenerator struct handles the randomization for us. Once it's created,
 we request from the database all proxies with this name. This is a fast search
 because the node we are searching is indexed by name. If there is ony one, it
 will be the one you just created, and you can have that proxy. The appropriate
 controllers are notified. If there is more than one, you tried creating a proxy
 that already existed and we delete the one you just made and try again.
 
 ***** Deleting A Proxy *****
 
 When you delete a proxy, you don't see that proxy or its convos, and stop
 receiving notifications for them (until you restore it). Any user attempting to
 contact that proxy will not know that you deleted the proxy.
 
 When deleting a proxy, loop through all its conversations and set
 'proxyDeleted' to true for both your copies of that convo. Then set the proxy's
 'deleted' to true. Then create an entry for it's key in
 
    /deleted/uid/proxy.key
 
 Also decrement your global unread by the proxy's unread.
 
 When loading proxies and convos, if 'deleted' and 'proxyDeleted' are true,
 don't load that proxy/convo, respectively.
 
 Deleted proxies show up in your 'Deleted Proxies' in 'Settings'. This view
 shows everything you have in /deleted/uid/. You can restore a proxy, and when
 that happens, set all it's conversation's 'proxyDeleted' to false for both
 copies of the convo, and set the proxy's 'deleted' to false. Then delete the
 proxy's entry in /deleted/uid/. Lastly, increment your global unread by the 
 proxy's unread.
 
 ***** Sending A Message For The First Time *****
 
 When sending a message, if we do not know if a conversation exists betweeen the
 two proxies (because the sender sent it from the 'New Message' view, we must
 check. If it is their first contact with each other, we must create a different
 convo struct for sender and receiver.
 
 Each owner of a convo keeps track of their own 'senderId', 'senderProxy',
 'recieverId', 'receiverProxy', 'convoNickname', and 'unread'. These all get set
 at this point.
 
 The convo's key in the database is the two proxys' names alphebatized and
 concatenated.
 
 We now pull the receiver's users/uid/blocked and see if we the sender's uid is
 on that list. If so, set the receiver's convos' 'blocked' to true.
 
 We can now save all this data atomically in a block.
 
 Then send it off to our normal messaging function to finish the job.
 
 In addition, we increment both user's 'Proxies Interacted With'.
 
 ***** Sending A Message In An Existing Convo *****
 
 To send a message, we must update several nodes in the database:
 
    sender side:

        - sender's convo last message and timestamp
        - sender's proxy/convo last message and timestamp
        - sender's proxy last message and timestamp
        - sender's 'Messages Sent' incremented
 
    receiver side:
 
        - receiver's convo last message, timestamp, and unread
        - receiver's proxy/convo last message, timestamp, and unread
        - receiver's 'Messages Received' incremented*
 
        * Note: This means you can see when people you have blocked are still
        sending you messages because your 'Messages Received' goes up. That's
        okay.
 
        During one of these transactions, check 'blocked' and 'proxyDeleted'
        in the convo struct.
        
        if !blocked && !proxyDeleted
            - update receiver's global unread
 
        if !blocked
            - update receiver's proxy last message, timestamp, and unread
 
    neutral side:
 
        - the actual message
 
 All writes on the sender's side can be done atomically with 
 updateChildValues().
 All writes on the receiver's side must be done in individual transactions since
 they involve incrementing an Int.
 
 ***** The Convo *****
 
 ***** Leaving A Convo *****
 
 When you leave a convo, set 'left' to true.
 When loading up your convos, if left == true, don't add it to the convos array
 for table refresh.
 When a message is sent, set the receiver's left back to false. They will again
 see the convo.
 They will continue to see your messages again until they block you.
 Lasty, decrement your corresponding proxy's and global unread by the convo's
 unread value.
 
 ***** Do Not Disturb *****
 
 When you mute a convo, you stop getting push notifications for it.
 
 ***** Blocking Users *****
 
 When you block a user, set the 'blocked' in your two copies of the convo to
 true. 
 
 Then loop through all your convos, if the receiverId matches this user's id,
 set that convo's 'blocked' to true as well, again for both your copies of the
 convo.
 
 When you load convos in your home view or proxy info view, if a convo's
 'blocked' is true, then don't load it.
 
 When someone sends you a message and it is the first message between the two
 proxies, they will pull your /blocked/uid. If their uid exists in your blocked,
 they will send you a message as normal, except that your two copies of the
 convo will have 'blocked' == true, and your proxy and global unread will not
 increment. This means if you unblock that user, you will then see all messages
 they have been sending you, from any proxy. (Your unread counts do not go up by
 the messages you missed while they were blocked, however.)
 
 Keep a copy of the users you have blocked as
    
    /blocked/uid/blockedUserId/blockedUserProxy
 
 blockedUserProxy is the proxy name you blocked the user as.
 
 You can see those you have blocked somewhere in Settings -> Blocked Users,
 represented as blockedUserProxy.
 
 You can unblock users, and when this happens, loop through all your convos,
 if the receiverId matches the userId you unblocked, set that convo's 'blocked'
 to false, for both copies of your convo. Then increment your proxy for that 
 convo's unread and your global unread by that convo's unread.
 
 Then delete that user's entry in your /blocked/uid/blockedUserId.
 
 ***** Reading A Convo *****
 
 Being inside a convo activates an observer that keeps track of the conv's
 unread. So when entering a convo, you "read" all the messages in it, and the
 unread counts for the convo (in both places), proxy, and your global unread
 are decremented by what was living in the unread count before you entered it.
 From here on out, as long as you're in the convo, any continued messages you
 receive in the convo will automatically be marked as read, and all
 corresponding unread values decremented accordingly.
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
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