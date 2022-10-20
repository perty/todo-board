package se.agical.todo.board;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.awt.*;
import java.net.URI;

@Component
public class BrowserLauncher {

    @Value("${server.port}")
    private String portNumber;

    @EventListener(ApplicationReadyEvent.class)
    public void launchBrowser() {
        System.setProperty("java.awt.headless", "false");
        Desktop desktop = Desktop.getDesktop();
        try {
            desktop.browse(new URI("http://localhost:" + portNumber));
        } catch (Exception e) {
            System.err.println(e.getMessage());
        }
    }
}