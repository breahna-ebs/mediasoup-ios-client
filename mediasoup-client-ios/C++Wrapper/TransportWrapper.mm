//
//  TransportWrapper.mm
//  mediasoup-client-ios
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

#define MSC_CLASS "transport_wrapper"

#import <Foundation/Foundation.h>
#import <libmediasoupclient/include/Logger.hpp>

#import "include/TransportWrapper.h"

using namespace mediasoupclient;

@implementation TransportWrapper : NSObject

+(NSString *)getNativeId:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    const std::string nativeId = [TransportWrapper extractNativeTransport:nativeTransport]->GetId();
    
    return [NSString stringWithUTF8String:nativeId.c_str()];
}

+(NSString *)getNativeConnectionState:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    const std::string nativeConnectionState = [TransportWrapper extractNativeTransport:nativeTransport]->GetConnectionState();
    
    return [NSString stringWithUTF8String:nativeConnectionState.c_str()];
}

+(NSString *)getNativeAppData:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    const std::string nativeAppData = [TransportWrapper extractNativeTransport:nativeTransport]->GetAppData().dump();
    
    return [NSString stringWithUTF8String:nativeAppData.c_str()];
}

+(NSString *)getNativeStats:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    try {
        const std::string nativeStats = [TransportWrapper extractNativeTransport:nativeTransport]->GetStats().dump();
        
        return [NSString stringWithUTF8String:nativeStats.c_str()];
    } catch(const std::exception &e) {
        MSC_ERROR("%s", e.what());
        NSString *message = [NSString stringWithUTF8String:e.what()];
        NSException* exception = [NSException exceptionWithName:@"RuntimeException" reason:message userInfo:nil];
        
        throw exception;
        
        return nullptr;
    }
}

+(bool)isNativeClosed:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    return [TransportWrapper extractNativeTransport:nativeTransport]->IsClosed();
}

+(void)nativeRestartIce:(NSValue *)nativeTransport iceParameters:(NSString *)iceParameters {
    MSC_TRACE();
    
    try {
        nlohmann::json iceParametersJson = nlohmann::json::object();
        
        if (iceParameters != nullptr) {
            iceParametersJson = nlohmann::json::parse(std::string([iceParameters UTF8String]));
        }
        
        [TransportWrapper extractNativeTransport:nativeTransport]->RestartIce(iceParametersJson);
    } catch (const std::exception &e) {
        MSC_ERROR("%s", e.what());
        NSString *message = [NSString stringWithUTF8String:e.what()];
        NSException* exception = [NSException exceptionWithName:@"RuntimeException" reason:message userInfo:nil];
        
        throw exception;
    }
}

+(void)nativeUpdateIceServers:(NSValue *)nativeTransport iceServers:(NSString *)iceServers {
    MSC_TRACE();
    
    try {
        auto iceServersJson = nlohmann::json::array();
        
        if (iceServers != nullptr) {
            iceServersJson = nlohmann::json::parse(std::string([iceServers UTF8String]));
        }
        
        [TransportWrapper extractNativeTransport:nativeTransport]->UpdateIceServers(iceServersJson);
    } catch (const std::exception &e) {
        MSC_ERROR("%s", e.what());
        NSString *message = [NSString stringWithUTF8String:e.what()];
        NSException* exception = [NSException exceptionWithName:@"RuntimeException" reason:message userInfo:nil];
        
        throw exception;
    }
}

+(void)nativeClose:(NSValue *)nativeTransport {
    MSC_TRACE();
    
    [TransportWrapper extractNativeTransport:nativeTransport]->Close();
}

+(NSValue *)nativeGetNativeTransport:(NSValue *)nativeTransport {
    MSC_DEBUG();
    
    return [NSValue valueWithPointer:[TransportWrapper extractNativeTransport:nativeTransport]];
}

+(NSValue *)nativeProduce:(NSValue *)nativeTransport listener:(id<ProducerListener>)listener track:(NSUInteger)mediaTrack encodings:(NSArray *)encodings codecOptions:(NSString *)codecOptions appData:(NSString *)appData {
    MSC_TRACE();
    
    try {
        auto producerListener = new ProducerListenerWrapper(listener);
        auto mediaStreamTrack = reinterpret_cast<webrtc::MediaStreamTrackInterface *>(mediaTrack);
        
        __block std::vector<webrtc::RtpEncodingParameters> encodingsVector;
        
        if(encodings != nullptr) {
            encodingsVector.reserve(encodings.count);
            
            // Build the equvilent c++ encoding from objective-c encoding
            for (RTCRtpEncodingParameters *encoding in encodings) {
                webrtc::RtpEncodingParameters nativeEncoding;
                nativeEncoding.active = encoding.isActive;
                
                if (encoding.maxBitrateBps != nil) nativeEncoding.max_bitrate_bps = (int)(size_t)encoding.maxBitrateBps;
                if (encoding.minBitrateBps != nil) nativeEncoding.min_bitrate_bps = (int)(size_t)encoding.minBitrateBps;
                if (encoding.maxFramerate != nil) nativeEncoding.max_framerate = (int)(size_t)encoding.maxFramerate;
                if (encoding.numTemporalLayers != nil) nativeEncoding.num_temporal_layers = (int)(size_t)encoding.numTemporalLayers;
                if (encoding.scaleResolutionDownBy != nil) nativeEncoding.scale_resolution_down_by = (double)[encoding.scaleResolutionDownBy doubleValue];
                
                encodingsVector.emplace_back(nativeEncoding);
            }
        }
        
        nlohmann::json codecOptionsJson = nlohmann::json::object();
        
        if (codecOptions != nullptr) {
            codecOptionsJson = nlohmann::json::parse(std::string([codecOptions UTF8String]));
        }
        
        nlohmann::json appDataJson = nlohmann::json::object();
        
        if (appData != nullptr) {
            appDataJson = nlohmann::json::parse(std::string([appData UTF8String]));
        }
        
        mediasoupclient::SendTransport *transport = reinterpret_cast<mediasoupclient::SendTransport *>([nativeTransport pointerValue]);
        mediasoupclient::Producer *producer = transport->Produce(producerListener, mediaStreamTrack, &encodingsVector, &codecOptionsJson, appDataJson);
        OwnedProducer *ownedProducer = new OwnedProducer(producer, producerListener);
        
        return [NSValue valueWithPointer:ownedProducer];
    } catch (std::exception &e) {
        MSC_ERROR("%s", e.what());
        NSString *message = [NSString stringWithUTF8String:e.what()];
        NSException* exception = [NSException exceptionWithName:@"RuntimeException" reason:message userInfo:nil];
        
        throw exception;
        
        return nullptr;
    }
}

+(NSValue *)nativeConsume:(NSValue *)nativeTransport listener:(id<ConsumerListener>)listener id:(NSString *)id producerId:(NSString *)producerId kind:(NSString *)kind rtpParameters:(NSString *)rtpParameters appData:(NSString *)appData {
    MSC_TRACE();
    
    try {
        auto consumerListener = new ConsumerListenerWrapper(listener);
        const std::string idString = std::string([id UTF8String]);
        const std::string producerIdString = std::string([producerId UTF8String]);
        const std::string kindString = std::string([kind UTF8String]);
        nlohmann::json rtpParametersJson = nlohmann::json::object();
        
        if (rtpParameters != nullptr) {
            rtpParametersJson = nlohmann::json::parse(std::string([rtpParameters UTF8String]));
        }
        
        nlohmann::json appDataJson = nlohmann::json::object();
        
        if (appData != nullptr) {
            appDataJson = nlohmann::json::parse(std::string([appData UTF8String]));
        }
        
        mediasoupclient::RecvTransport *transport = reinterpret_cast<mediasoupclient::RecvTransport *>([nativeTransport pointerValue]);
        mediasoupclient::Consumer *nativeConsumer = transport->Consume(consumerListener, idString, producerIdString, kindString, &rtpParametersJson, appDataJson);
        
        OwnedConsumer *consumer = new OwnedConsumer(nativeConsumer, consumerListener);
        
        return [NSValue valueWithPointer:consumer];
    } catch (std::exception &e) {
        MSC_ERROR("%s", e.what());
        NSString *message = [NSString stringWithUTF8String:e.what()];
        NSException* exception = [NSException exceptionWithName:@"RuntimeException" reason:message userInfo:nil];
        
        throw exception;
        
        return nullptr;
    }
}

+(mediasoupclient::Transport *)extractNativeTransport:(NSValue *)nativeTransport {
    mediasoupclient::Transport *transport = reinterpret_cast<mediasoupclient::Transport *>([nativeTransport pointerValue]);
    MSC_ASSERT(transport != nullptr, "native transport pointer null");
    
    return transport;
}

@end