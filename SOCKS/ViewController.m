#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()
@property (nonatomic, strong) NETunnelProviderManager *manager;
@end

@implementation ViewController

static ViewController *sharedInstance = nil;

+ (void)logMessage:(NSString *)message {
    if (sharedInstance) {
        [sharedInstance appendLog:message];
    } else {
        NSLog(@"%@", message);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sharedInstance = self;
    self.logTextView.editable = NO;
    self.logTextView.text = @"";
    self.statusLabel.text = @"Loading configuration…";
    self.statsLabel.text = @"vk-turn-proxy via Packet Tunnel";

    [self appendLog:@"[APP] Initializing network extension manager"];
    [self loadOrCreateManager];
}

- (void)loadOrCreateManager {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"[APP] Failed to load managers: %@", error.localizedDescription]];
            dispatch_async(dispatch_get_main_queue(), ^{ self.statusLabel.text = @"Configuration error"; });
            return;
        }

        self.manager = managers.firstObject ?: [[NETunnelProviderManager alloc] init];
        NETunnelProviderProtocol *proto = [[NETunnelProviderProtocol alloc] init];
        proto.providerBundleIdentifier = @"com.nanako.socksbypass.turnproxy.extension";
        proto.serverAddress = @"vk-turn-proxy";
        proto.providerConfiguration = @{
            @"peer": @"127.0.0.1:56000",
            @"listen": @"127.0.0.1:9000",
            @"threads": @16,
            @"transport": @"tcp",
            @"vk_link": @"https://vk.com/call/join/REPLACE_ME"
        };

        self.manager.protocolConfiguration = proto;
        self.manager.localizedDescription = @"VK TURN Proxy";
        self.manager.enabled = YES;

        [self.manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable saveError) {
            if (saveError) {
                [self appendLog:[NSString stringWithFormat:@"[APP] Failed to save manager: %@", saveError.localizedDescription]];
                dispatch_async(dispatch_get_main_queue(), ^{ self.statusLabel.text = @"Save failed"; });
                return;
            }

            [self appendLog:@"[APP] Manager saved. Starting tunnel…"];
            [self.manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable loadError) {
                if (loadError) {
                    [self appendLog:[NSString stringWithFormat:@"[APP] Failed to reload manager: %@", loadError.localizedDescription]];
                    dispatch_async(dispatch_get_main_queue(), ^{ self.statusLabel.text = @"Reload failed"; });
                    return;
                }

                NSError *startError = nil;
                BOOL started = [self.manager.connection startVPNTunnelAndReturnError:&startError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (started) {
                        self.statusLabel.text = @"Tunnel starting…";
                        [self appendLog:@"[APP] startVPNTunnel requested"];
                    } else {
                        self.statusLabel.text = @"Tunnel start failed";
                        [self appendLog:[NSString stringWithFormat:@"[APP] startVPNTunnel failed: %@", startError.localizedDescription]];
                    }
                });
            }];
        }];
    }];
}

- (void)appendLog:(NSString *)message {
    NSLog(@"%@", message);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *existing = self.logTextView.text ?: @"";
        self.logTextView.text = [existing stringByAppendingFormat:@"\n%@", message];
        NSRange range = NSMakeRange(self.logTextView.text.length, 0);
        [self.logTextView scrollRangeToVisible:range];
    });
}

@end
