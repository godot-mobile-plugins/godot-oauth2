//
// © 2025-present https://github.com/cengiz-pz
//

#import "oauth2_logger.h"

// Define and initialize the shared os_log_t instance
os_log_t oauth2_log;

__attribute__((constructor)) // Automatically runs at program startup
static void initialize_oauth2_log(void) {
	oauth2_log = os_log_create("org.godotengine.plugin.oauth2", "OAuth2Plugin");
}
