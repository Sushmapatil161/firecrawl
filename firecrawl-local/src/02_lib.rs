//! Firecrawl Local: the local primitive behind `firecrawl scrape|crawl|map`.
//!
//! The HTML cleaning, link extraction, metadata and crawl-filter modules are
//! compiled directly from `apps/api/native/src`, the same Rust the cloud API
//! loads through N-API. One source of truth means a page cleaned locally and a
//! page cleaned in the cloud go through identical code.
//!
//! A published crate carries a copy of those files in `src/native` (see
//! `build.rs` and `scripts/vendor-native.sh`).

#![allow(dead_code)]

// Standalone copy: the shared cleaning code always comes from src/native.
#[path = "native/utils.rs"]
mod utils;
#[path = "native/xml.rs"]
mod xml;

#[path = "native/html.rs"]
pub mod html;

#[path = "native/crawler.rs"]
pub mod crawler;

#[path = "native/document.rs"]
pub mod document;

// Files are numbered in the order a request flows through them.
#[path = "03_cloud.rs"]
pub mod cloud;
#[path = "04_scrape.rs"]
pub mod scrape;
#[path = "05_guard.rs"]
pub mod guard;
#[path = "06_fetch.rs"]
pub mod fetch;
#[path = "07_documents.rs"]
pub mod documents;
#[path = "08_browser.rs"]
pub mod browser;
#[path = "09_netguard.rs"]
pub mod netguard;
#[path = "10_markdown.rs"]
pub mod markdown;
#[path = "11_mem.rs"]
pub mod mem;
#[path = "12_crawl.rs"]
pub mod crawl;
#[path = "13_serve.rs"]
pub mod serve;
