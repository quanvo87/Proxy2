'use strict'

const functions = require('firebase-functions')
const admin = require('firebase-admin')

admin.initializeApp(functions.config().firebase)

exports.sendNewMessageNotification = functions.database.ref('/users/{uid}/unreadMessages/{messageKey}').onCreate((event) => {
    const uid = event.params.uid
    const message = event.data.val()
    console.log('New message: ', message)
    const getRegistrationTokensPromise = admin.database().ref(`/users/${uid}/registrationTokens`).once('value')
    const getUnreadMessageCountPromise = admin.database().ref(`/users/${uid}/unreadMessages`).once('value')
    return Promise.all([getRegistrationTokensPromise, getUnreadMessageCountPromise]).then((results) => {
        const registrationTokensSnapshot = results[0]
        if (!registrationTokensSnapshot.exists()) {
            return console.log('There are no notification tokens to send to.')
        }
        const unreadMessageCountSnapshot = results[1]
        const unreadMessageCount = unreadMessageCountSnapshot.numChildren()
        const payload = {
            notification: {
                badge: unreadMessageCount.toString(),
                body: message.senderDisplayName + ': ' + message.text,
                parentConvoKey: message.parentConvoKey,
                sound: 'newMessage.wav'
            }
        }
        const tokens = Object.keys(registrationTokensSnapshot.val())
        return admin.messaging().sendToDevice(tokens, payload).then((response) => {
            const removeTokenPromises = []
            response.results.forEach((result, index) => {
                const error = result.error
                const token = tokens[index]
                if (error) {
                    if (error.code === 'messaging/invalid-registration-token' || error.code === 'messaging/registration-token-not-registered') {
                        removeTokenPromises.push(registrationTokensSnapshot.ref.child(token).remove())
                        console.log('Removing invalid registration token: ', token)
                    } else {
                        console.error('Failure sending notification to registration token: ', token, error)
                    }
                } else {
                    console.log('Sent new message notification to registration token: ', token)
                }
            })
            return Promise.all(removeTokenPromises)
        })
    })
})

exports.cleanupSetConvoReceiverDeletedProxy = functions.database.ref('/convos/{uid}/{convoKey}/receiverDeletedProxy').onWrite((event) => {
    const uid = event.params.uid
    const convoKey = event.params.convoKey
    console.log('convos/', uid, '/', convoKey, '/receiverDeletedProxy set. Checking if cleanup required...')
    return cleanupConvo(uid, convoKey, event)
})

exports.cleanupSetConvoHasUnreadMessage = functions.database.ref('/convos/{uid}/{convoKey}/hasUnreadMessage').onWrite((event) => {
    const uid = event.params.uid
    const convoKey = event.params.convoKey
    console.log('convos/', uid, '/', convoKey, '/hasUnreadMessage set. Checking if cleanup required...')
    return cleanupConvo(uid, convoKey, event)
})

function cleanupConvo(uid, convoKey, event) {
    if (!event.data.exists()) {
        console.log('Event was a delete. No cleanup required.')
        return null
    }
    const convoRef = admin.database().ref(`/convos/${uid}/${convoKey}`)
    return convoRef.once('value').then((snapshot) => {
        if (snapshot.val() && snapshot.val().key) {
            return console.log('Convo exists. No action required.')
        } else {
            console.log('Convo didn\'t exist. Cleaning up.')
            return convoRef.remove()
        }
    })
}

exports.cleanupSetProxyHasUnreadMessage = functions.database.ref('/proxies/{uid}/{proxyKey}/hasUnreadMessage').onWrite((event) => {
    const uid = event.params.uid
    const proxyKey = event.params.proxyKey
    console.log('proxies/', uid, '/', proxyKey, '/hasUnreadMessage set. Checking if cleanup required...')
    if (!event.data.exists()) {
        console.log('Event was a delete. No cleanup required.')
        return null
    }
    const proxyRef = admin.database().ref(`/proxies/${uid}/${proxyKey}`)
    return proxyRef.once('value').then((snapshot) => {
        if (snapshot.val() && snapshot.val().key) {
            return console.log('Proxy exists. No action required.')
        } else {
            console.log('Proxy didn\'t exist. Cleaning up.')
            return proxyRef.remove()
        }
    })
})

exports.cleanupSetUnreadMessage = functions.database.ref('/users/{uid}/unreadMessages/{messageId}').onWrite((event) => {
    const uid = event.params.uid
    const messageId = event.params.messageId
    console.log('/users/', uid, '/unreadMessages/', messageId, ' set. Checking if cleanup required...')
    if (!event.data.exists()) {
        console.log('Event was a delete. No cleanup required.')
        return null
    }
    const message = event.data.val()
    return admin.database().ref(`/proxies/${uid}/${message.receiverProxyKey}`).once('value').then((snapshot) => {
        if (snapshot.val() && snapshot.val().key) {
            return console.log('Receiver proxy exists. No action required.')
        } else {
            console.log('Receiver proxy didn\'t exist. Cleaning up.')
            const removeUnreadMessagePromise = admin.database().ref(`/users/${uid}/unreadMessages/${messageId}`).remove()
            const setReceiverDeletedProxyPromise = admin.database().ref(`/convos/${message.senderId}/${message.parentConvoKey}`).update({
                'receiverDeletedProxy': true
            })
            return Promise.all([removeUnreadMessagePromise, setReceiverDeletedProxyPromise])
        }
    })
})