/*******************************************************************************
 * Copyright (C) 2016 Black Duck Software, Inc.
 * http://www.blackducksoftware.com/
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *******************************************************************************/
package com.blackducksoftware.integration.email.batch.processor;

import java.net.URISyntaxException;
import java.util.LinkedHashSet;
import java.util.Set;

import com.blackducksoftware.integration.email.model.batch.ItemEntry;
import com.blackducksoftware.integration.hub.api.policy.PolicyRule;
import com.blackducksoftware.integration.hub.dataservice.notification.item.PolicyContentItem;

public class PolicyEvent extends NotificationEvent<PolicyContentItem> {
    private final PolicyRule policyRule;

    public PolicyEvent(ProcessingAction action, NotificationCategoryEnum categoryType, PolicyContentItem notificationContent,
            PolicyRule policyRule) throws URISyntaxException {
        super(action, categoryType, notificationContent);
        this.policyRule = policyRule;
        init();
    }

    @Override
    public Set<ItemEntry> generateDataSet() {
        final Set<ItemEntry> dataSet = new LinkedHashSet<>(4);
        dataSet.add(new ItemEntry(ItemTypeEnum.RULE.name(), policyRule.getName()));
        dataSet.add(new ItemEntry(ItemTypeEnum.COMPONENT.name(), getNotificationContent().getComponentName()));
        dataSet.add(new ItemEntry("", getNotificationContent().getComponentVersion()));
        return dataSet;
    }

    @Override
    public String generateEventKey() throws URISyntaxException {
        final StringBuilder keyBuilder = new StringBuilder();
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_ISSUE_TYPE_NAME);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_SEPARATOR);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_ISSUE_TYPE_VALUE_POLICY);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_PAIR_SEPARATOR);

        keyBuilder.append(NotificationEventConstants.EVENT_KEY_HUB_PROJECT_VERSION_REL_URL_HASHED_NAME);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_SEPARATOR);
        keyBuilder.append(hashString(getNotificationContent().getProjectVersion().getRelativeUrl()));
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_PAIR_SEPARATOR);

        keyBuilder.append(NotificationEventConstants.EVENT_KEY_HUB_COMPONENT_REL_URL_HASHED_NAME);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_SEPARATOR);
        keyBuilder.append(hashString(getNotificationContent().getComponentRelativeUrl()));
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_PAIR_SEPARATOR);

        keyBuilder.append(NotificationEventConstants.EVENT_KEY_HUB_COMPONENT_VERSION_REL_URL_HASHED_NAME);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_SEPARATOR);
        keyBuilder.append(hashString(getNotificationContent().getComponentVersionRelativeUrl()));
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_PAIR_SEPARATOR);

        keyBuilder.append(NotificationEventConstants.EVENT_KEY_HUB_POLICY_RULE_REL_URL_HASHED_NAME);
        keyBuilder.append(NotificationEventConstants.EVENT_KEY_NAME_VALUE_SEPARATOR);
        keyBuilder.append(hashString(getPolicyRule().getMeta().getRelativeHref()));
        final String key = keyBuilder.toString();
        return key;
    }

    @Override
    public int countCategoryItems() {
        return 1;
    }

    public PolicyRule getPolicyRule() {
        return policyRule;
    }
}
