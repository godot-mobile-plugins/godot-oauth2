//
// © 2025-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>

#import "oauth2_plugin.h"
#import "oauth2_plugin.h"
#import "oauth2_logger.h"

#import "core/config/engine.h"


OAuth2Plugin *oauth2_plugin;


void oauth2_plugin_init() {
	os_log_debug(oauth2_log, "OAuth2Plugin: Initializing plugin at timestamp: %f", [[NSDate date] timeIntervalSince1970]);

	oauth2_plugin = memnew(OAuth2Plugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("OAuth2Plugin", oauth2_plugin));
	os_log_debug(oauth2_log, "OAuth2Plugin: Singleton registered");
}


void oauth2_plugin_deinit() {
	os_log_debug(oauth2_log, "OAuth2Plugin: Deinitializing plugin");
	oauth2_log = NULL; // Prevent accidental reuse

	if (oauth2_plugin) {
		memdelete(oauth2_plugin);
		oauth2_plugin = nullptr;
	}
}
