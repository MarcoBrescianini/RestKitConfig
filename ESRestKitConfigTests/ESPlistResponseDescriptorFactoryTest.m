//
//  ESPlistResponseDescriptorFactoryTest.m
//  Engineering Solutions
//
//  Created by Marco Brescianini on 16/10/15.
//  Copyright © 2015 Engineering Solutions. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RestKit/RestKit.h>

#import "ESPlistResponseDescriptorFactory.h"

#import "ESConfigFixtures.h"
#import "ESDictionaryResponseDescriptorFactory.h"

@interface ESPlistResponseDescriptorFactoryTest : XCTestCase {
    ESPlistResponseDescriptorFactory * factory;

    NSDictionary<NSString *, RKMapping *> *mappingMap;
    id fooMappingMock;
    id barMappingMock;
}
@end

@implementation ESPlistResponseDescriptorFactoryTest

- (void)setUp
{
    [super setUp];

    fooMappingMock = OCMClassMock([RKEntityMapping class]);
    barMappingMock = OCMClassMock([RKEntityMapping class]);

    mappingMap = @{
            @"foo" : fooMappingMock,
            @"bar" : barMappingMock
    };

}

//-------------------------------------------------------------------------------------------
#pragma mark - Initialization Tests


- (void)testInitWithEmptyMappingThrows
{
    XCTAssertThrows([[ESPlistResponseDescriptorFactory alloc] initWithConfig:@{}]);
    XCTAssertThrows([[ESPlistResponseDescriptorFactory alloc] initWithConfig:@{}]);
}

- (void)testInitWithEmptyConfigDictionaryThrows
{
    XCTAssertThrows([[ESPlistResponseDescriptorFactory alloc] initWithConfig:nil]);
    XCTAssertThrows([[ESPlistResponseDescriptorFactory alloc] initWithConfig:@{}]);
}

- (void)testCanInitWithConfigDictionary
{
    NSDictionary * config = @{
            @"desc" : @{
            }
    };

    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];

    XCTAssertNotNil(factory);
    XCTAssertNotNil(factory.config);
}

#warning Skipped Test

- (void)_testCanInitFromMainBundle
{
    factory = [[ESPlistResponseDescriptorFactory alloc] initWithFilename:@"Response"];

    XCTAssertNotNil(factory);
    XCTAssertNotNil(factory.config);
}

- (void)testCanInitWithFilepath
{
    NSString * filepath;

    @try
    {
        NSDictionary * conf = [ESConfigFixtures responseConfigDictionary];
        filepath = [ESConfigFixtures writeResponseFile:conf];

        factory = [[ESPlistResponseDescriptorFactory alloc] initWithFilepath:filepath];

        XCTAssertNotNil(factory);
        XCTAssertNotNil(factory.config);

    }
    @finally
    {
        if (filepath)
        {
            NSFileManager * manager = [NSFileManager new];
            if ([manager fileExistsAtPath:filepath])
            {
                [manager removeItemAtPath:filepath error:nil];
            }
        }
    }

}

//-------------------------------------------------------------------------------------------
#pragma mark - Business Logic Tests

- (void)testDescriptorForName
{
    NSDictionary * config = @{
            @"desc" : @{
                    @"route" : @"foo/",
                    @"keypath" : @"keypath",
                    @"method" : @"GET",
                    @"mapping" : @"foo",
                    @"statusCode" : @200
            }
    };
    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];

    RKResponseDescriptor *descriptor = [factory createDescriptorNamed:@"desc" forMappings:mappingMap];
    RKResponseDescriptor * expectedDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:fooMappingMock method:RKRequestMethodGET pathPattern:@"foo/" keyPath:@"keypath" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    OCMStub([fooMappingMock isEqualToMapping:OCMOCK_ANY]).andReturn(YES);

    XCTAssertTrue([descriptor isEqualToResponseDescriptor:expectedDescriptor]);
}

- (void)testResponseDescriptorForAnyMethod
{
    NSDictionary *config = @{
            @"desc": @{
                    @"keypath"   : @"keypath",
                    @"method"    : @"Any",
                    @"mapping"   : @"foo",
                    @"statusCode": @200
            }
    };

    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];

    RKResponseDescriptor *descriptor = [factory createDescriptorNamed:@"desc" forMappings:mappingMap];
    RKResponseDescriptor *expectedDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:fooMappingMock method:RKRequestMethodAny pathPattern:nil keyPath:@"keypath" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    OCMStub([fooMappingMock isEqualToMapping:OCMOCK_ANY]).andReturn(YES);

    XCTAssertTrue([descriptor isEqualToResponseDescriptor:expectedDescriptor]);
}

- (void)testMethodNotFoundThrows
{
    NSDictionary * config = @{
            @"desc" : @{
                    @"route" : @"foo",
                    @"keypath" : @"keypath",
                    @"method" : @"ASD",
                    @"mapping" : @"foo",
                    @"statusCode" : @200
            }
    };

    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];

    XCTAssertThrowsSpecificNamed([factory createDescriptorNamed:@"desc" forMappings:mappingMap], NSException, @"PlistMalformedException");
}

- (void)testStatusCodeNotFoundThrows
{
    NSDictionary * config = @{
            @"desc" : @{
                    @"route" : @"foo",
                    @"keypath" : @"keypath",
                    @"method" : @"GET",
                    @"mapping" : @"foo",
                    @"statusCode" : @1200
            }
    };
    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];
    XCTAssertThrowsSpecificNamed([factory createDescriptorNamed:@"desc" forMappings:mappingMap], NSException, @"PlistMalformedException");
}

- (void)testMappingNotFoundThrows
{
    NSDictionary * config = @{
            @"desc" : @{
                    @"route" : @"foo",
                    @"keypath" : @"keypath",
                    @"method" : @"GET",
                    @"mapping" : @"mapping2",
                    @"statusCode" : @200
            }
    };
    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];
    XCTAssertThrowsSpecificNamed([factory createDescriptorNamed:@"desc" forMappings:mappingMap], NSException, @"PlistMalformedException");
}

- (void)testCreateResponseDescriptors
{
    NSDictionary * config = @{
            @"foo" : @{
                    @"route" : @"foo/",
                    @"keypath" : @"keypath",
                    @"method" : @"GET",
                    @"mapping" : @"foo",
                    @"statusCode" : @200
            },
            @"bar" : @{
                    @"route" : @"bar/",
                    @"keypath" : @"keypath",
                    @"method" : @"POST",
                    @"mapping" : @"bar",
                    @"statusCode" : @200
            }
    };
    factory = [[ESPlistResponseDescriptorFactory alloc] initWithConfig:config];

    NSArray<RKResponseDescriptor *> *descriptors = [factory createAllDescriptors:mappingMap];

    XCTAssertNotNil(descriptors);
    XCTAssertEqual(descriptors.count, 2);

    RKResponseDescriptor * fooDesc = [RKResponseDescriptor responseDescriptorWithMapping:fooMappingMock method:RKRequestMethodGET pathPattern:@"foo/" keyPath:@"keypath" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    OCMStub([fooMappingMock isEqualToMapping:OCMOCK_ANY]).andReturn(YES);

    XCTAssertTrue([descriptors[0] isEqualToResponseDescriptor:fooDesc]);

    RKResponseDescriptor * barDesc = [RKResponseDescriptor responseDescriptorWithMapping:barMappingMock method:RKRequestMethodPOST pathPattern:@"bar/" keyPath:@"keypath" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    OCMStub([barMappingMock isEqualToMapping:OCMOCK_ANY]).andReturn(YES);

    XCTAssertTrue([descriptors[1] isEqualToResponseDescriptor:barDesc]);
}

@end
