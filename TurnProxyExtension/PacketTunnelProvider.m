#import "PacketTunnelProvider.h"
#include <spawn.h>
#include <signal.h>

extern char **environ;

@interface PacketTunnelProvider ()
@property (nonatomic, assign) pid_t clientPid;
@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self configureTunnel:^(NSError * _Nullable cfgError) {
        if (cfgError) { completionHandler(cfgError); return; }
        NSError *launchError = nil;
        if (![self launchClient:&launchError]) { completionHandler(launchError); return; }
        completionHandler(nil);
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    if (self.clientPid > 0) { kill(self.clientPid, SIGTERM); self.clientPid = 0; }
    completionHandler();
}

- (void)configureTunnel:(void (^)(NSError * _Nullable error))completion {
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"127.0.0.1"];
    settings.MTU = @1280;
    NEIPv4Settings *ipv4 = [[NEIPv4Settings alloc] initWithAddresses:@[@"10.99.0.2"] subnetMasks:@[@"255.255.255.255"]];
    ipv4.includedRoutes = @[[NEIPv4Route defaultRoute]];
    settings.IPv4Settings = ipv4;
    settings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"1.1.1.1", @"8.8.8.8"]];
    [self setTunnelNetworkSettings:settings completionHandler:completion];
}

- (BOOL)launchClient:(NSError **)error {
    NSString *binaryPath = [[NSBundle mainBundle] pathForResource:@"vk-turn-client" ofType:nil inDirectory:@"Tools"];
    if (!binaryPath) {
        if (error) *error = [NSError errorWithDomain:@"TurnProxyExtension" code:102 userInfo:@{NSLocalizedDescriptionKey: @"vk-turn-client binary missing"}];
        return NO;
    }

    NSDictionary *cfg = ((NETunnelProviderProtocol *)self.protocolConfiguration).providerConfiguration ?: @{};
    NSString *peer = cfg[@"peer"] ?: @"127.0.0.1:56000";
    NSString *listen = cfg[@"listen"] ?: @"127.0.0.1:9000";
    NSString *vkLink = cfg[@"vk_link"] ?: @"";
    NSString *threads = [cfg[@"threads"] description] ?: @"16";

    NSMutableArray<NSString *> *args = [NSMutableArray arrayWithArray:@[@"-peer", peer, @"-listen", listen, @"-vk-link", vkLink, @"-n", threads]];
    if ([[(cfg[@"transport"] ?: @"tcp") lowercaseString] isEqualToString:@"udp"]) [args addObject:@"-udp"];

    int argc = (int)args.count + 1;
    char **argv = calloc((size_t)argc + 1, sizeof(char *));
    argv[0] = strdup(binaryPath.UTF8String);
    for (int i = 0; i < args.count; i++) argv[i + 1] = strdup(args[i].UTF8String);

    pid_t pid = 0;
    int rc = posix_spawn(&pid, binaryPath.UTF8String, NULL, NULL, argv, environ);

    for (int i = 0; i < argc; i++) free(argv[i]);
    free(argv);

    if (rc != 0) {
        if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:rc userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"posix_spawn failed: %d", rc]}];
        return NO;
    }

    self.clientPid = pid;
    return YES;
}

@end
