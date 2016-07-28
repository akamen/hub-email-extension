package com.blackducksoftware.integration.email.notifier;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.blackducksoftware.integration.email.model.EmailSystemProperties;
import com.blackducksoftware.integration.hub.notification.api.PolicyOverrideNotificationItem;

@Component
public class PolicyViolationOverrideCancelRouter extends AbstractEmailRouter<PolicyOverrideNotificationItem> {

	private final Logger logger = LoggerFactory.getLogger(PolicyViolationOverrideCancelRouter.class);

	@Override
	public void configure(final EmailSystemProperties data) {
		logger.info("Configuration data event received for " + getClass().getName() + ": " + data);
	}

	@Override
	public void receive(final List<PolicyOverrideNotificationItem> data) {
		logger.info("Received notification data event received for " + getClass().getName() + ": " + data);
	}

	@Override
	public void send(final Map<String, Object> data) {
		// TODO Auto-generated method stub

	}

	@Override
	public Set<String> getConfigureEventTopics() {
		final Set<String> topics = new LinkedHashSet<>();
		topics.add("emailconfigtopic");
		return topics;
	}

	@Override
	public Set<String> getReceiveEventTopics() {
		final Set<String> topics = new LinkedHashSet<>();
		topics.add(PolicyOverrideNotificationItem.class.getName());
		return topics;
	}
}
