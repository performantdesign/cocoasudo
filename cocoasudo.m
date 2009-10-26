//
//  cocoasudo.m
//
//  Created by Aaron Kardell on 10/19/2009.
//  Copyright 2009 Performant Design, LLC. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	int retVal = 1;
	int programArgsStartAt = 1;
	char *icon = NULL;
	char *prompt = NULL;

	for (; programArgsStartAt < argc; programArgsStartAt++)
	{
		if (!strncmp("--icon=", argv[programArgsStartAt], 7))
		{
			icon = argv[programArgsStartAt] + 7;
		}
		else if (!strncmp("--prompt=", argv[programArgsStartAt], 9))
		{
			prompt = argv[programArgsStartAt] + 9;
			size_t promptLen = strlen(prompt);
			char *newPrompt = malloc(sizeof(char) * (promptLen + 2));
			strcpy(newPrompt, prompt);
			newPrompt[promptLen] = '\n';
			newPrompt[promptLen + 1] = '\n';
			newPrompt[promptLen + 2] = '\0';
			prompt = newPrompt;
		}
		else
		{
			break;
		}
	}

	OSStatus status;
	AuthorizationRef authRef;
	
	AuthorizationItem right = { "com.performant.cocoasudo", 0, NULL, 0 };
	AuthorizationRights rightSet = { 1, &right };
	
	AuthorizationEnvironment myAuthorizationEnvironment;
	AuthorizationItem kAuthEnv[2];
	myAuthorizationEnvironment.items = kAuthEnv;

	if (prompt && icon)
	{
		kAuthEnv[0].name = kAuthorizationEnvironmentPrompt;
		kAuthEnv[0].valueLength = strlen(prompt);
		kAuthEnv[0].value = prompt;
		kAuthEnv[0].flags = 0;

		kAuthEnv[1].name = kAuthorizationEnvironmentIcon;
		kAuthEnv[1].valueLength = strlen(icon);
		kAuthEnv[1].value = icon;
		kAuthEnv[1].flags = 0;
		
		myAuthorizationEnvironment.count = 2;
	}
	else if (prompt)
	{
		kAuthEnv[0].name = kAuthorizationEnvironmentPrompt;
		kAuthEnv[0].valueLength = strlen(prompt);
		kAuthEnv[0].value = prompt;
		kAuthEnv[0].flags = 0;
		
		myAuthorizationEnvironment.count = 1;
	}
	else if (icon)
	{
		kAuthEnv[0].name = kAuthorizationEnvironmentIcon;
		kAuthEnv[0].valueLength = strlen(icon);
		kAuthEnv[0].value = icon;
		kAuthEnv[0].flags = 0;

		myAuthorizationEnvironment.count = 1;
	}
	else
	{
		myAuthorizationEnvironment.count = 0;
	}

	if (AuthorizationCreate(NULL, &myAuthorizationEnvironment/*kAuthorizationEmptyEnvironment*/, kAuthorizationFlagDefaults, &authRef) != errAuthorizationSuccess)
	{
		NSLog(@"Could not create authorization reference object.");
		status = errAuthorizationBadAddress;
	}
	else
	{
		status = AuthorizationCopyRights(authRef, &rightSet, &myAuthorizationEnvironment/*kAuthorizationEmptyEnvironment*/, 
										 kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize
										 | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights,
										 NULL);
	}
	
	if (status == errAuthorizationSuccess)
	{
		status = AuthorizationExecuteWithPrivileges(authRef, argv[programArgsStartAt], 0, argv + programArgsStartAt + 1, NULL);
		
		pid_t pid;
		int pidStatus;
		do {
			pid = wait(&pidStatus);
		} while (pid != -1);
		
		if (status == errAuthorizationSuccess)
		{
			retVal = 0;
		}
	}
	else
	{
		AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
		authRef = NULL;
		if (status != errAuthorizationCanceled)
		{
			// pre-auth failed
			NSLog(@"Pre-auth failed");
		}
	}

	if (prompt) {
		free(prompt);
	}
	
	[pool release];
	return retVal;
}
