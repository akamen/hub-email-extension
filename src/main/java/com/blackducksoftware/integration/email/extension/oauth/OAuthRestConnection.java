package com.blackducksoftware.integration.email.extension.oauth;

import java.io.IOException;
import java.net.URISyntaxException;

import org.restlet.Context;
import org.restlet.resource.ClientResource;

import com.blackducksoftware.integration.hub.rest.RestConnection;

public class OAuthRestConnection extends RestConnection {

	private final TokenManager tokenManager;
	private AccessType accessType;

	public OAuthRestConnection(final String baseUrl) {
		super(baseUrl);
		this.tokenManager = new TokenManager();
	}

	public TokenManager getTokenManager() {
		return tokenManager;
	}

	public void applyAccessType(final AccessType accessType) {
		this.accessType = accessType;
	}

	@Override
	public ClientResource createClientResource(final String providedUrl, final Context context)
			throws URISyntaxException {
		try {
			return tokenManager.createClientResource(providedUrl, accessType);
		} catch (final IOException e) {
			return super.createClientResource(providedUrl, context);
		}
	}
}
