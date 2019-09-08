title=Grails: Nested Validation in Command Objects
date=2018-09-25
type=post
tags=groovy,grails,grails33,testing,validation,ripplr
status=published
~~~~~~

If you've ever found yourself in need of validating nested Grails command objects, you've likely done something similar to the below snippet:

<?prettify?>

	static constraints = {
		profile validator: { val, obj -> val.validate() }
	}

This works well if you want to prevent someone from submitting a form without filling out the required profile data, however, the default error message leaves a lot to be desired.

<!--more-->

<ul class="errors" style="color: #D8000C; background-color: #FFD2D2;">
 	<li>Property [profile] of class [class com.joelforjava.ripplr.UserRegisterCommand] with value [com.joelforjava.ripplr.ProfileRegisterCommand@1a247d8f] does not pass custom validation</li>
</ul>

You can try something along the lines of a custom toString implementation for the nested command object, but you're still left with a messy looking error message and users are not going to try and decipher this.

<ul class="errors" style="color: #D8000C; background-color: #FFD2D2;">
 	<li>Property [profile] of class [class com.joelforjava.ripplr.UserRegisterCommand] with value [com.joelforjava.ripplr.ProfileRegisterCommand(mainPhoto:com.joelforjava.ripplr.ImageUploadCommand@2f29c2bd,
coverPhoto:com.joelforjava.ripplr.ImageUploadCommand@6f5b2b54, fullName:null, about:null, homepage:null, email:null, twitterProfile:null, facebookProfile:null, timezone:America/New_York, country:null, skin:null)] does not pass custom validation</li>
</ul>

Now it just looks like we've made the application extra, extra angry. Fortunately, there's a better way of handling this through a more sophisticated validation closure that takes three parameters, with the third parameter being the `org.springframework.validation.Errors` object. This gives us a lot more power to work with when handling how the nested object is validated and the accompanying error messages.

When the nested command object fails validation, we can iterate through all of the errors on the object and pass them on to the errors object with a custom message key (for use with `messages.properties`) and pass the rest of the error information on to the errors object. We can also add a default error message if our message key is not found.

<?prettify?>

	static constraints = {
		profile validator: { ProfileRegisterCommand val, UserRegisterCommand obj, Errors errors ->
			if (!val.validate()) {
				val.errors.allErrors.each { err ->
					def fieldName = err.arguments ? err.arguments[0] : err.properties['field']
					if (fieldName) {
						String errorCode = "profile.${err.code}"
						if (val.hasProperty(fieldName)) {
							errorCode = "profile.${err.arguments[0]}.${err.code}"
						}
						errors.rejectValue("profile.${err.properties['field']}", errorCode, err.arguments, "Invalid value for {0}")
					}
				}
			}
		}
	}

In this code, I have explicitly listed out the types for `val`, `obj`, and `errors`, but I typically leave them off. This new code will iterate through each error found on the `ProfileRegisterCommand` object, create a new error code, and then call `rejectValue` on the errors object.

We have two possibilities for the error code. The first form is using `"profile.${err.code}"`, where err.code could be along the lines of `nullable`, `maxSize.exceeded`, or `email.invalid`. We check to see if the profile has a property named by the fieldName, which could be `fullName`, `email`, or `mainPhoto.photo`, etc. If the profile has a property with this name, then we update the error code to be `"profile.${err.arguments[0]}.${err.code}"` which becomes `profile.email.email.invalid` for an invalid email address value for the email property or `profile.fullName.nullable` for a null fullName value. Since `mainPhoto.photo` is not a property on `val`, the error code would remain `profile.mainPhoto.photo.maxSize.exceeded` in the case of the `mainPhoto.photo` exceeding the maxSize constraint.

Now, when we submit the empty registration page, we see some new error messages:

<ul class="errors" style="color: #D8000C; background-color: #FFD2D2;">
 	<li>Invalid value for fullName</li>
 	<li>Invalid value for email</li>
</ul>

These messages are based on the default error message we set in the call to `errors.rejectValue`. We can further customize the error messages via `messages.properties`. We take the newly created error code and use it to create a message, similar to the following.

	profile.fullName.nullable=Please provide your name
	profile.email.nullable=Please provide your email address. We won't spam you!

And now we can see the new error messages:

<ul class="errors" style="color: #D8000C; background-color: #FFD2D2;">
 	<li>Please provide your name</li>
 	<li>Please provide your email address. We wont spam you!</li>
</ul>

If your nested command objects have further nested command objects or any objects that require custom validation, you would continue with a pattern similar to this and add new messages to messages.properties in order for custom error messages to display when there are validation issues.