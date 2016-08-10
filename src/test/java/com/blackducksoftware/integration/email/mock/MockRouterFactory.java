package com.blackducksoftware.integration.email.mock;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import com.blackducksoftware.integration.email.model.CustomerProperties;
import com.blackducksoftware.integration.email.notifier.routers.AbstractEmailRouter;
import com.blackducksoftware.integration.email.notifier.routers.EmailTaskData;
import com.blackducksoftware.integration.email.notifier.routers.factory.AbstractEmailFactory;
import com.blackducksoftware.integration.email.service.EmailMessagingService;
import com.blackducksoftware.integration.email.transforms.templates.AbstractContentTransform;
import com.blackducksoftware.integration.hub.notification.NotificationService;

public class MockRouterFactory extends AbstractEmailFactory {
	public final static String TOPIC_KEY = "MockTopic";
	private final String expectedData;

	public MockRouterFactory(final EmailMessagingService emailMessagingService,
			final CustomerProperties customerProperties, final NotificationService notificationService,
			final Map<String, AbstractContentTransform> transformMap, final String expectedData) {
		super(emailMessagingService, customerProperties, notificationService, transformMap);
		this.expectedData = expectedData;
	}

	@Override
	public Set<String> getSubscriberTopics() {
		final Set<String> subscriberSet = new HashSet<>();
		subscriberSet.add(TOPIC_KEY);
		return subscriberSet;
	}

	@Override
	public AbstractEmailRouter<?> createInstance(final EmailTaskData data) {
		return new MockRouter(getEmailMessagingService(), getCustomerProperties(), getNotificationService(),
				getTransformMap(), data, expectedData);
	}

}
