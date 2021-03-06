﻿/********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author     :	Luis Majano
Date        :	9/3/2007
Description :
	Request service Test
**/
component extends="coldbox.system.testing.BaseTestCase"{
	
	this.loadColdBox = true;

	function setup(){
		super.setup();
		
		//Mocks
		mockFactory  = getMockBox().createEmptyMock(className='coldbox.system.cache.CacheFactory');
		mockEventManager  = getMockBox().createEmptyMock(className='coldbox.system.core.events.EventPoolManager');
		mockLogBox	 = getMockBox().createEmptyMock("coldbox.system.logging.LogBox");
		mockLogger	 = getMockBox().createEmptyMock("coldbox.system.logging.Logger");	
		// Mock Methods
		mockFactory.$("getLogBox",mockLogBox);
		mockLogBox.$("getLogger", mockLogger);
		mockLogger.$("error").$("debug").$("info").$("canDebug",true).$("canInfo",true).$("canError",true);
		mockEventManager.$("processState");
		
		config = {
            objectDefaultTimeout = 15,
            opQueueMaxBlockTime = 5000,
	        opTimeout = 5000,
	        timeoutExceptionThreshold = 5000,
	        ignoreCouchBaseTimeouts = true,				
        	bucket="default",
        	password="",
        	servers="127.0.0.1:8091",
        	// This switches the internal provider from normal cacheBox to coldbox enabled cachebox
			coldboxEnabled = false
        };
		
		// Create Provider
		// Find a way to make the "couchbaseApp" mapping dynamic for people (like Brad) running this in the root :)
		cache = getMockBox().createMock("CouchbaseProvider.models.Couchbase.Provider").init();
		// Decorate it
		cache.setConfiguration( config );
		cache.setCacheFactory( mockFactory );
		cache.setEventManager( mockEventManager );
		
		// Configure the provider
		cache.configure();
	}
	
	function testShutdown(){
		//cache.shutdown();
	}
	
	function testLookup(){
		// null test
		cache.$("get");
		assertFalse( cache.lookup( 'invalid' ) );
		
		// something
		cache.$("get", this);
		assertTrue( cache.lookup( 'valid' ) );	
	}
	
	function testLookupQuiet(){
		// null test
		cache.$("get");
		assertFalse( cache.lookupQuiet( 'invalid' ) );
		
		// something
		cache.$("get", this);
		assertTrue( cache.lookupQuiet( 'valid' ) );	
	}
	
	function testGet(){
		// null value
		r = cache.get( 'invalid' );
		assertTrue( isNull( r ) );
			
		testVal = {name="luis", age=32};
		cache.getObjectStore().set( "unittestkey", 500, serializeJSON( testVal ) );
		
		results = cache.get( 'unittestkey' );
		assertEquals( testVal, deserializeJSON( results ) );
	}
	
	function testGetQuiet(){
		testGet();
	}
	
	function testGetSize(){
		currentSize = cache.getSize();
		future = cache.getObjectStore().set( "unitTestKey#createUUID()#", 500, 'Testing' );
		future.get();
		
		assertTrue( isNumeric( cache.getSize() ) );
		assertTrue( currentSize lt cache.getSize() );
	}
	
	function testExpireObject(){
		// test not valid object
		cache.expireObject( "invalid" );
		// test real object
		cache.getObjectStore().set( "unitTestKey", 500, 'Testing' );
		cache.expireObject( "unitTestKey" );
		results = cache.get( 'unitTestKey' );
		assertTrue( isNull( results ) );
	}
	
	function testExpireAll(){
		cache.getObjectStore().set( "unitTestKey", 500, 'Testing' );
		cache.expireAll();
		// no asserts, just let it run
	}
	
	function testClear(){
		cache.getObjectStore().set( "unitTestKey", 500, 'Testing' );
		r = cache.getObjectStore().delete( "unitTestKey" );
		r.get();
		assertTrue( isNull( cache.getObjectStore().get( "unitTestKey" ) ) );
	}
	
	function testClearQuiet(){
		testClear();
	}
	
	function testReap(){
		cache.reap();
	}
	
	function testSetQuiet(){
		// not simple value
		testVal = {name="luis", age=32};
		cache.setQuiet( 'unitTestKey', testVal, 1 );
		
		results = cache.getObjectStore().get( "unittestkey" );
		
		assertTrue( len( results ) );
		assertTrue( isJSON( results ) );
		
		// simple values with different cases
		cache.setQuiet( 'anotherKey', 'Hello Couchbase', 1 );
		results = cache.getObjectStore().get( "anotherkey" );
		assertTrue( len( results ) );
		assertTrue( isJSON( results ) );
	}
	
	function testSet(){
		// not simple value
		testVal = {name="luis", age=32};
		cache.set( 'unitTestKey', testVal, 1 );
		
		results = cache.getObjectStore().get( "unittestkey" );
		
		assertTrue( len( results ) );
		assertTrue( isJSON( results ) );
		
		// simple values with different cases
		cache.set( 'anotherKey', 'Hello Couchbase', 1 );
		results = cache.getObjectStore().get( "anotherkey" );
		assertTrue( len( results ) );
		assertTrue( isJSON( results ) );
	}
	
	function testGetCachedObjectMetadata(){
		cache.getObjectStore().set( "unittestkey", 500, 'Test Data' );
		r = cache.getCachedObjectMetadata( 'unittestkey' );
		assertFalse( r.isExpired );
	}
	
	function testGetKeys(){
		f = cache.getObjectStore().set( "unittestkey", 500, 'Test Data' );
		f.get();
		results = cache.getKeys();
		assertTrue( arrayFindNoCase( results, "unittestkey" ) );
	}
	
	function testgetStoreMetadataReport(){
		f = cache.getObjectStore().set( "unittestkey", 500, 'Test Data' );
		f.get();
		r = cache.getStoreMetadataReport();
		assertTrue( arrayFindNoCase( structKeyArray( r ), "unittestkey" ) );
	}
	
}