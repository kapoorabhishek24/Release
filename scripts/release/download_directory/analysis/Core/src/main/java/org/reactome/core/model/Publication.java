package org.reactome.core.model;

// Generated Jul 8, 2011 1:48:55 PM by Hibernate Tools 3.4.0.CR1

import javax.xml.bind.annotation.XmlRootElement;
import java.util.List;

/**
 * Publication generated by hbm2java
 */
@XmlRootElement
public class Publication extends DatabaseObject {

    private String title;
    private List<Person> author;

    public List<Person> getAuthor() {
        return author;
    }

    public void setAuthor(List<Person> author) {
        this.author = author;
    }

    public Publication() {
    }

    public String getTitle() {
        return this.title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

}
