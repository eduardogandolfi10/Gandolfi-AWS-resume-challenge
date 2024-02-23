import re
from typing import Generator
import pytest
from playwright.sync_api import Page, expect, APIRequestContext, Playwright
import boto3
import configparser


config = configparser.ConfigParser()
config.read('config.ini')


@pytest.fixture(scope="session")
def api_request_context(
    playwright: Playwright,
) -> Generator[APIRequestContext, None, None]:
    request_context = playwright.request.new_context(
        base_url=config['config']['base_url'])
    yield request_context
    request_context.dispose()


def test_has_title(page: Page):
    page.goto(config['config']['website_url'])

    # Expect a title "to contain" a substring.
    expect(page).to_have_title(re.compile("Resume"))


def test_download_link(page: Page):
    page.goto(config['config']['website_url'])

    # Click the get started link.
    with page.expect_download() as download_info:
        page.get_by_text("Download").click()
    download = download_info.value
    download.save_as(download.suggested_filename)


def test_api_success(api_request_context: APIRequestContext):
    name = 'Eduardo'
    session = boto3.Session(profile_name=config['config']['profile_name'], region_name=config['config']['region'])
    dynamodb = boto3.resource('dynamodb', region_name=config['config']['region'])

    table = dynamodb.Table(config['config']['db'])

    a = (table.get_item(Key={'Name': 'Eduardo'}))
    view = a['Item']['view_count']
    expected_view = int(view) + 1
    expected_view = str(expected_view)
    get_request = api_request_context.get(f"/sandbox/update-view-count?name={name}")
    assert get_request.ok
    get_response = get_request.json()
    assert get_response[name] == expected_view
    a = (table.get_item(Key={'Name': 'Eduardo'}))
    new_view = a['Item']['view_count']
    assert new_view == expected_view


def test_api_format_error(api_request_context: APIRequestContext):
    name = 'Eduardo'
    session = boto3.Session(profile_name=config['config']['profile_name'], region_name=config['config']['region'])
    dynamodb = boto3.resource('dynamodb', region_name=config['config']['region'])

    table = dynamodb.Table(config['config']['db'])

    a = (table.get_item(Key={'Name': 'Eduardo'}))
    view = a['Item']['view_count']
    expected_view = view
    get_request = api_request_context.get(f"/sandbox/update-view-count")
    assert get_request.ok
    get_response = get_request.json()
    assert get_response['errorMessage'] == "'name'"
    # assert get_response[name] == expected_view
    a = (table.get_item(Key={'Name': 'Eduardo'}))
    new_view = a['Item']['view_count']
    assert new_view == expected_view
