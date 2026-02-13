//
// © 2025-present https://github.com/cengiz-pz
//

#ifndef oauth2_plugin_h
#define oauth2_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/object.h"
#include "core/object/class_db.h"


class OAuth2Plugin : public Object {
	GDCLASS(OAuth2Plugin, Object);

private:
	static OAuth2Plugin* instance; // Singleton instance

	static void _bind_methods();

	void cleanup_expired_tokens();

public:
	static OAuth2Plugin* get_singleton();

	PackedStringArray get_all_keys();

	void save_token(String key, String value);

	String get_token(String key);

	void delete_token(String key);

	OAuth2Plugin();
	~OAuth2Plugin();
};

#endif /* oauth2_plugin_h */
