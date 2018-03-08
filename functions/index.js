'use strict'

const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)

exports.sendNewMessageNotification = functions.database.ref('/users/{uid}/unreadMessages/{messageKey}').onCreate((event) => {
    const uid = event.params.uid
    const message = event.data.val()
    console.log('New message: ', message)
    return admin.database().ref(`/users/${uid}/registrationTokens`).once('value').then((snapshot) => {
        if (!snapshot.exists()) {
            return console.log('There are no notification tokens to send to.')
        }
        const tokens = Object.keys(snapshot.val())
        const payload = {
            notification: {
                body: message.senderDisplayName + ': ' + message.text,
                messageText: message.text,
                parentConvoKey: message.parentConvoKey,
                senderDisplayName: message.senderDisplayName
            }
        }
        return admin.messaging().sendToDevice(tokens, payload).then((response) => {
            const removeTokenPromises = []
            response.results.forEach((result, index) => {
                const error = result.error
                const token = tokens[index]
                if (error) {
                    if (error.code === 'messaging/invalid-registration-token' || error.code === 'messaging/registration-token-not-registered') {
                        removeTokenPromises.push(snapshot.ref.child(token).remove())
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