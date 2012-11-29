//
//  main.m
//  Next
//
//  Created by jorin vogel on 11/29/12.
//  Copyright (c) 2012 jorin vogel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
