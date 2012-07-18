//
//  RestoMenu.m
//  Hydra
//
//  Created by Pieter De Baets on 17/07/12.
//  Copyright (c) 2012 Zeus WPI. All rights reserved.
//

#import "RestoMenu.h"

@implementation RestoMenu

@synthesize day, open, meat, vegetables, soup;

- (NSString *)description
{
    NSUInteger count = [meat count] + [vegetables count];
    return [NSString stringWithFormat:@"<RestoMenu for %@ (%d items)>", day, count];
}

+ (void)registerObjectMappingWith:(RKObjectMappingProvider *)mappingProvider;
{
    // Create mapping for menu-item
    RKObjectMapping *itemMapping = [RKObjectMapping mappingForClass:[RestoMenuItem class]];
    [itemMapping mapAttributes:@"name", @"price", @"recommended", nil];

    // Create mapping for menu
    RKObjectMapping *menuMapping = [RKObjectMapping mappingForClass:self];
    [menuMapping setForceCollectionMapping:YES];
    [menuMapping mapKeyOfNestedDictionaryToAttribute:@"day"];
    [menuMapping mapKeyPath:@"(day).meat" toRelationship:@"meat" withMapping:itemMapping];
    [menuMapping mapKeyPath:@"(day).soup" toRelationship:@"soup" withMapping:itemMapping];
    [menuMapping mapKeyPath:@"(day).open" toAttribute:@"open"];
    [menuMapping mapKeyPath:@"(day).vegetables" toAttribute:@"vegetables"];

    // Date format: 2012-03-26
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [menuMapping setDateFormatters:[NSArray arrayWithObject:dateFormatter]];

    // Register mapping
    [mappingProvider setObjectMapping:menuMapping forKeyPath:@""];
}

@end

@implementation RestoMenuItem

@synthesize name, price, recommended;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<RestoMenuItem: %@ (%@)>", name, price];
}

@end