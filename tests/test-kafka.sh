#!/bin/bash
# Test script for Kafka

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
SERVICE_NAME="kafka"
KAFKA_HOST="${KAFKA_HOST:-kafka}"
KAFKA_PORT="${KAFKA_PORT:-9092}"
BOOTSTRAP_SERVER="${KAFKA_HOST}:${KAFKA_PORT}"
TEST_TOPIC="test_topic_$(date +%s)"
TEST_MESSAGE="Hello from Kafka test at $(date)"

print_header "Kafka"

# Cleanup function
cleanup() {
    info "Cleaning up test resources..."
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --delete --topic "$TEST_TOPIC" 2>/dev/null || true
}

# Test 1: Connectivity (list topics)
test_connectivity() {
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list > /dev/null 2>&1
}

# Test 2: Create topic
test_create_topic() {
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --create --topic "$TEST_TOPIC" \
        --partitions 1 --replication-factor 1 > /dev/null 2>&1
}

# Test 3: List topics (verify created)
test_list_topics() {
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -q "$TEST_TOPIC"
}

# Test 4: Describe topic
test_describe_topic() {
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --describe --topic "$TEST_TOPIC" 2>/dev/null | grep -q "PartitionCount"
}

# Test 5: Produce message
test_produce_message() {
    echo "$TEST_MESSAGE" | kafka-console-producer.sh \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --topic "$TEST_TOPIC" 2>/dev/null
}

# Test 6: Consume message
test_consume_message() {
    result=$(timeout 10 kafka-console-consumer.sh \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --topic "$TEST_TOPIC" \
        --from-beginning \
        --max-messages 1 2>/dev/null)
    [ "$result" = "$TEST_MESSAGE" ]
}

# Test 7: Produce multiple messages
test_produce_multiple() {
    for i in 1 2 3; do
        echo "Message $i" | kafka-console-producer.sh \
            --bootstrap-server "$BOOTSTRAP_SERVER" \
            --topic "$TEST_TOPIC" 2>/dev/null
    done
}

# Test 8: Consume multiple messages
test_consume_multiple() {
    count=$(timeout 10 kafka-console-consumer.sh \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --topic "$TEST_TOPIC" \
        --from-beginning \
        --max-messages 4 2>/dev/null | wc -l)
    [ "$count" -ge 4 ]
}

# Test 9: Delete topic
test_delete_topic() {
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --delete --topic "$TEST_TOPIC" > /dev/null 2>&1
}

# Test 10: Verify topic deleted
test_verify_topic_deleted() {
    # Give Kafka a moment to process the deletion
    sleep 2
    ! kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -q "^${TEST_TOPIC}$"
}

# Main test execution
main() {
    # Check if kafka tools are available
    if ! command -v kafka-topics.sh &> /dev/null; then
        # Try to find Kafka tools in common locations
        if [ -d "/opt/kafka/bin" ]; then
            export PATH="/opt/kafka/bin:$PATH"
        elif [ -d "/usr/local/kafka/bin" ]; then
            export PATH="/usr/local/kafka/bin:$PATH"
        else
            fail "Kafka CLI tools not found. Please install Kafka or add kafka/bin to PATH."
            print_summary "Kafka"
            exit 1
        fi
    fi

    # Run tests
    run_test "Connectivity to Kafka" test_connectivity
    run_test "Create topic '${TEST_TOPIC}'" test_create_topic
    run_test "List topics (verify created)" test_list_topics
    run_test "Describe topic" test_describe_topic
    run_test "Produce message" test_produce_message
    run_test "Consume message" test_consume_message
    run_test "Produce multiple messages" test_produce_multiple
    run_test "Consume multiple messages" test_consume_multiple
    run_test "Delete topic" test_delete_topic
    run_test "Verify topic deleted" test_verify_topic_deleted

    print_summary "Kafka"
}

main "$@"
