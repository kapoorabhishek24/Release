package org.reactome.core.model;

import javax.xml.bind.annotation.XmlRootElement;

// Generated Jul 8, 2011 1:48:55 PM by Hibernate Tools 3.4.0.CR1

/**
 * Url generated by hbm2java
 */
@XmlRootElement
public class URL extends Publication {

    private String uniformResourceLocator;

    public URL() {
    }

    public String getUniformResourceLocator() {
        return this.uniformResourceLocator;
    }

    public void setUniformResourceLocator(String uniformResourceLocator) {
        this.uniformResourceLocator = uniformResourceLocator;
    }

}
