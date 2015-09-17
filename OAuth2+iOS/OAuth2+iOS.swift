//
//  OAuth2+iOS.swift
//  OAuth2
//
//  Created by Pascal Pfiffner on 4/19/15.
//  Copyright 2015 Pascal Pfiffner
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import SafariServices


extension OAuth2
{
	/**
	Uses `UIApplication` to open the authorize URL in iOS's browser.
	
	- parameter params: Additional parameters to pass to the authorize URL
	- returns: A bool indicating success
	*/
	public final func openAuthorizeURLInBrowser(params: [String: String]? = nil) -> Bool {
		do {
			let url = try authorizeURL(params)
			return UIApplication.sharedApplication().openURL(url)
		}
		catch let err {
			logIfVerbose("Cannot open authorize URL: \((err as NSError).localizedDescription)")
		}
		return false
	}
	
	
	// MARK: - Built-In Web View
	
	/**
	Tries to use the current auth config context, which on iOS should be a UIViewController, to present the authorization screen.
	
	- returns: A bool indicating whether the method was able to show the authorize screen
	*/
	public func authorizeEmbeddedWith(config: OAuth2AuthConfig, params: [String: String]? = nil, autoDismiss: Bool = true) -> Bool {
		if let controller = config.authorizeContext as? UIViewController {
			if #available(iOS 9, *), config.ui.useSafariView, let web = authorizeSafariEmbeddedFrom(controller, params: params) {
				if autoDismiss {
					internalAfterAuthorizeOrFailure = { wasFailure, error in
						web.dismissViewControllerAnimated(true, completion: nil)
					}
				}
				return true
			}
			if let web = authorizeEmbeddedFrom(controller, params: params) {
				if autoDismiss {
					internalAfterAuthorizeOrFailure = { wasFailure, error in
						web.dismissViewControllerAnimated(true, completion: nil)
					}
				}
				return true
			}
		}
		return false
	}
	
	
	// MARK: - Safari Web View Controller
	
	/**
	Presents a Safari view controller from the supplied view controller, loading the authorize URL.
	
	The mechanism works just like when you're using Safari itself to log the user in, hence you **need to implement**
	`application(application:openURL:sourceApplication:annotation:)` in your application delegate.
	
	This method does NOT dismiss the view controller automatically, you probably want to do this in the `afterAuthorizeOrFailure` closure.
	Simply call this method first, then call `dismissViewController()` on the returned web view controller instance in that closure. Or use
	`authorizeEmbeddedWith()` which does all this automatically.
	
	- parameter controller: The view controller to use for presentation
	- parameter params: Optional additional URL parameters
	- returns: SFSafariViewController, being already presented automatically
	*/
	@available(iOS 9.0, *)
	public func authorizeSafariEmbeddedFrom(controller: UIViewController, params: [String: String]? = nil) -> SFSafariViewController? {
		do {
			let url = try authorizeURL(params)
			return presentSafariViewFor(url, from: controller)
		}
		catch let err {
			logIfVerbose("Cannot present authorize URL: \((err as NSError).localizedDescription)")
		}
		return nil
	}
	
	/**
	Presents a Safari view controller from the supplied view controller, loading the authorize URL.
	
	The mechanism works just like when you're using Safari itself to log the user in, hence you **need to implement**
	`application(application:openURL:sourceApplication:annotation:)` in your application delegate.
	
	Automatically intercepts the redirect URL and performs the token exchange. It does NOT however dismiss the web view controller
	automatically, you probably want to do this in the `afterAuthorizeOrFailure` closure. Simply call this method first, then assign
	that closure in which you call `dismissViewController()` on the returned web view controller instance.
	
	- parameter controller: The view controller to use for presentation
	- parameter redirect: The redirect URL to use
	- parameter scope: The scope to use
	- parameter params: Optional additional URL parameters
	- returns: SFSafariViewController, being already presented automatically
	*/
	@available(iOS 9.0, *)
	public func authorizeSafariEmbeddedFrom(controller: UIViewController, redirect: String, scope: String, params: [String: String]? = nil) -> SFSafariViewController? {
			do {
				let url = try authorizeURLWithRedirect(redirect, scope: scope, params: params)
				return presentSafariViewFor(url, from: controller)
			}
			catch let err {
				logIfVerbose("Cannot present authorize URL: \((err as NSError).localizedDescription)")
			}
			return nil
	}
	
	/**
	Presents and returns a Safari view controller loading the given URL and intercepting the given URL.
	
	- returns: SFSafariViewController, embedded in a UINavigationController being presented automatically
	*/
	@available(iOS 9.0, *)
	final func presentSafariViewFor(url: NSURL, from: UIViewController) -> SFSafariViewController {
		let web = SFSafariViewController(URL: url)
		web.title = authConfig.ui.title
		
		from.presentViewController(web, animated: true, completion: nil)
		
		return web
	}
	
	
	// MARK: - Custom Web View Controller
	
	/**
	Presents a web view controller, contained in a UINavigationController, on the supplied view controller and loads the authorize URL.
	
	Automatically intercepts the redirect URL and performs the token exchange. It does NOT however dismiss the web view controller
	automatically, you probably want to do this in the `afterAuthorizeOrFailure` closure. Simply call this method first, then assign
	that closure in which you call `dismissViewController()` on the returned web view controller instance.
	
	- parameter controller: The view controller to use for presentation
	- parameter params: Optional additional URL parameters
	- returns: OAuth2WebViewController, embedded in a UINavigationController being presented automatically
	*/
	public func authorizeEmbeddedFrom(controller: UIViewController, params: [String: String]? = nil) -> OAuth2WebViewController? {
		do {
			let url = try authorizeURL(params)
			return presentAuthorizeViewFor(url, intercept: redirect!, from: controller)
		}
		catch let err {
			logIfVerbose("Cannot present authorize URL: \((err as NSError).localizedDescription)")
		}
		return nil
	}
	
	/**
	Presents a web view controller, contained in a UINavigationController, on the supplied view controller and loads the authorize URL.
	
	Automatically intercepts the redirect URL and performs the token exchange. It does NOT however dismiss the web view controller
	automatically, you probably want to do this in the `afterAuthorizeOrFailure` closure. Simply call this method first, then assign
	that closure in which you call `dismissViewController()` on the returned web view controller instance.
	
	- parameter controller: The view controller to use for presentation
	- parameter redirect: The redirect URL to use
	- parameter scope: The scope to use
	- parameter params: Optional additional URL parameters
	- returns: OAuth2WebViewController, embedded in a UINavigationController being presented automatically
	*/
	public func authorizeEmbeddedFrom(controller: UIViewController,
	                                    redirect: String,
	                                       scope: String,
		                                  params: [String: String]? = nil) -> OAuth2WebViewController? {
		do {
			let url = try authorizeURLWithRedirect(redirect, scope: scope, params: params)
			return presentAuthorizeViewFor(url, intercept: redirect, from: controller)
		}
		catch let err {
			logIfVerbose("Cannot present authorize URL: \((err as NSError).localizedDescription)")
		}
		return nil
	}
	
	/**
	Presents and returns a web view controller loading the given URL and intercepting the given URL.
	
	- returns: OAuth2WebViewController, embedded in a UINavigationController being presented automatically
	*/
	final func presentAuthorizeViewFor(url: NSURL, intercept: String, from: UIViewController) -> OAuth2WebViewController {
		let web = OAuth2WebViewController()
		web.title = authConfig.ui.title
		web.backButton = authConfig.ui.backButton as? UIBarButtonItem
		web.startURL = url
		web.interceptURLString = intercept
		web.onIntercept = { url in
			do {
				try self.handleRedirectURL(url)
				return true
			}
			catch let err {
				self.logIfVerbose("Cannot intercept redirect URL: \((err as NSError).localizedDescription)")
			}
			return false
		}
		web.onWillDismiss = { didCancel in
			if didCancel {
				self.didFail(nil)
			}
		}
		
		let navi = UINavigationController(rootViewController: web)
		from.presentViewController(navi, animated: true, completion: nil)
		
		return web
	}
}

