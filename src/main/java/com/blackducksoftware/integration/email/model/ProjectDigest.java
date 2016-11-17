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
package com.blackducksoftware.integration.email.model;

import java.util.HashMap;
import java.util.Map;

public class ProjectDigest {
    private final Map<String, String> projectData;

    private final Map<String, FreemarkerTarget> categoryMap;

    private final FreemarkerTarget policyViolations;

    private final FreemarkerTarget policyOverrides;

    private final FreemarkerTarget vulnerabilities;

    public ProjectDigest(final Map<String, String> projectData, final FreemarkerTarget policyViolations,
            final FreemarkerTarget policyOverrides, final FreemarkerTarget vulnerabilities) {
        this.projectData = projectData;
        this.policyViolations = policyViolations;
        this.policyOverrides = policyOverrides;
        this.vulnerabilities = vulnerabilities;
        this.categoryMap = new HashMap<>();
    }

    public Map<String, String> getProjectData() {
        return projectData;
    }

    public FreemarkerTarget getPolicyViolations() {
        return policyViolations;
    }

    public FreemarkerTarget getPolicyOverrides() {
        return policyOverrides;
    }

    public FreemarkerTarget getVulnerabilities() {
        return vulnerabilities;
    }
}
