package se.agical.todo.board;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.awt.Toolkit;
import java.awt.Taskbar;
import java.awt.Image;
import java.net.URL;

@Component
public final class AppIcon {

    @EventListener(ApplicationReadyEvent.class)
    public void setIcon() {
        final URL imageResource = AppIcon.class.getClassLoader().getResource("images/todo.png");
        if (imageResource != null) {
            final Image image = getToolkit().getImage(imageResource);
            try {
                Taskbar.getTaskbar().setIconImage(image);
            } catch (UnsupportedOperationException | SecurityException e) {
                System.err.println(e.getMessage());
            }
        }
    }

    private  Toolkit getToolkit() {
        System.setProperty("java.awt.headless", "false");
        return Toolkit.getDefaultToolkit();
    }
}
 